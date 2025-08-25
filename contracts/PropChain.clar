;; title: PropChain
;; version: 1.0.0
;; summary: Tokenized Real Estate Fractional Ownership Protocol
;; description: A protocol to represent fractional ownership of real estate as digital tokens





(define-fungible-token propchain-token)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPERTY_NOT_FOUND (err u101))
(define-constant ERR_INSUFFICIENT_TOKENS (err u102))
(define-constant ERR_PROPERTY_NOT_ACTIVE (err u103))
(define-constant ERR_INVALID_AMOUNT (err u104))
(define-constant ERR_PROPERTY_ALREADY_EXISTS (err u105))
(define-constant ERR_VOTING_PERIOD_EXPIRED (err u106))
(define-constant ERR_ALREADY_VOTED (err u107))
(define-constant ERR_TRANSFER_FAILED (err u108))
(define-constant ERR_INVALID_PERCENTAGE (err u109))

(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var next-property-id uint u1)
(define-data-var token-name (string-ascii 32) "PropChain")
(define-data-var token-symbol (string-ascii 32) "PROP")
(define-data-var token-decimals uint u6)

(define-map properties
  { property-id: uint }
  {
    owner: principal,
    total-value: uint,
    total-tokens: uint,
    location: (string-utf8 256),
    description: (string-utf8 512),
    is-active: bool,
    created-at: uint
  }
)

(define-map property-ownership
  { property-id: uint, owner: principal }
  { token-amount: uint }
)

(define-map property-proposals
  { property-id: uint, proposal-id: uint }
  {
    proposer: principal,
    description: (string-utf8 512),
    voting-deadline: uint,
    votes-for: uint,
    votes-against: uint,
    is-executed: bool
  }
)

(define-map user-votes
  { property-id: uint, proposal-id: uint, voter: principal }
  { vote: bool, voting-power: uint }
)

(define-map property-dividends
  { property-id: uint }
  { total-dividend: uint, dividend-per-token: uint, last-distribution: uint }
)

(define-map user-dividend-claims
  { property-id: uint, user: principal }
  { last-claimed-block: uint }
)

(define-public (create-property (total-value uint) (total-tokens uint) (location (string-utf8 256)) (description (string-utf8 512)))
  (let (
    (property-id (var-get next-property-id))
  )
    (asserts! (> total-value u0) ERR_INVALID_AMOUNT)
    (asserts! (> total-tokens u0) ERR_INVALID_AMOUNT)
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    
    (map-set properties
      { property-id: property-id }
      {
        owner: tx-sender,
        total-value: total-value,
        total-tokens: total-tokens,
        location: location,
        description: description,
        is-active: true,
        created-at: stacks-block-height
      }
    )
    
    (try! (ft-mint? propchain-token total-tokens tx-sender))
    (var-set next-property-id (+ property-id u1))
    (ok property-id)
  )
)

(define-public (purchase-tokens (property-id uint) (token-amount uint))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
    (current-ownership (default-to { token-amount: u0 } (map-get? property-ownership { property-id: property-id, owner: tx-sender })))
  )
    (asserts! (get is-active property) ERR_PROPERTY_NOT_ACTIVE)
    (asserts! (> token-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (<= token-amount (ft-get-balance propchain-token (get owner property))) ERR_INSUFFICIENT_TOKENS)
    
    (try! (ft-transfer? propchain-token token-amount (get owner property) tx-sender))
    
    (map-set property-ownership
      { property-id: property-id, owner: tx-sender }
      { token-amount: (+ (get token-amount current-ownership) token-amount) }
    )
    
    (ok true)
  )
)

(define-public (transfer-tokens (property-id uint) (token-amount uint) (recipient principal))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
    (sender-ownership (unwrap! (map-get? property-ownership { property-id: property-id, owner: tx-sender }) ERR_INSUFFICIENT_TOKENS))
    (recipient-ownership (default-to { token-amount: u0 } (map-get? property-ownership { property-id: property-id, owner: recipient })))
  )
    (asserts! (get is-active property) ERR_PROPERTY_NOT_ACTIVE)
    (asserts! (> token-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= (get token-amount sender-ownership) token-amount) ERR_INSUFFICIENT_TOKENS)
    
    (map-set property-ownership
      { property-id: property-id, owner: tx-sender }
      { token-amount: (- (get token-amount sender-ownership) token-amount) }
    )
    
    (map-set property-ownership
      { property-id: property-id, owner: recipient }
      { token-amount: (+ (get token-amount recipient-ownership) token-amount) }
    )
    
    (ok true)
  )
)

(define-public (create-proposal (property-id uint) (description (string-utf8 512)))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
    (user-ownership (unwrap! (map-get? property-ownership { property-id: property-id, owner: tx-sender }) ERR_UNAUTHORIZED))
    (proposal-id u1)
  )
    (asserts! (get is-active property) ERR_PROPERTY_NOT_ACTIVE)
    (asserts! (> (get token-amount user-ownership) u0) ERR_UNAUTHORIZED)
    
    (map-set property-proposals
      { property-id: property-id, proposal-id: proposal-id }
      {
        proposer: tx-sender,
        description: description,
        voting-deadline: (+ stacks-block-height u1440),
        votes-for: u0,
        votes-against: u0,
        is-executed: false
      }
    )
    
    (ok proposal-id)
  )
)

(define-public (vote-on-proposal (property-id uint) (proposal-id uint) (vote bool))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
    (proposal (unwrap! (map-get? property-proposals { property-id: property-id, proposal-id: proposal-id }) ERR_PROPERTY_NOT_FOUND))
    (user-ownership (unwrap! (map-get? property-ownership { property-id: property-id, owner: tx-sender }) ERR_UNAUTHORIZED))
    (voting-power (get token-amount user-ownership))
  )
    (asserts! (get is-active property) ERR_PROPERTY_NOT_ACTIVE)
    (asserts! (< stacks-block-height (get voting-deadline proposal)) ERR_VOTING_PERIOD_EXPIRED)
    (asserts! (is-none (map-get? user-votes { property-id: property-id, proposal-id: proposal-id, voter: tx-sender })) ERR_ALREADY_VOTED)
    (asserts! (> voting-power u0) ERR_UNAUTHORIZED)
    
    (map-set user-votes
      { property-id: property-id, proposal-id: proposal-id, voter: tx-sender }
      { vote: vote, voting-power: voting-power }
    )
    
    (map-set property-proposals
      { property-id: property-id, proposal-id: proposal-id }
      (merge proposal {
        votes-for: (if vote (+ (get votes-for proposal) voting-power) (get votes-for proposal)),
        votes-against: (if vote (get votes-against proposal) (+ (get votes-against proposal) voting-power))
      })
    )
    
    (ok true)
  )
)

(define-public (distribute-dividends (property-id uint) (total-dividend uint))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
    (dividend-per-token (/ total-dividend (get total-tokens property)))
  )
    (asserts! (is-eq tx-sender (get owner property)) ERR_UNAUTHORIZED)
    (asserts! (get is-active property) ERR_PROPERTY_NOT_ACTIVE)
    (asserts! (> total-dividend u0) ERR_INVALID_AMOUNT)
    
    (map-set property-dividends
      { property-id: property-id }
      {
        total-dividend: total-dividend,
        dividend-per-token: dividend-per-token,
        last-distribution: stacks-block-height
      }
    )
    
    (ok dividend-per-token)
  )
)

(define-public (claim-dividends (property-id uint))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
    (user-ownership (unwrap! (map-get? property-ownership { property-id: property-id, owner: tx-sender }) ERR_UNAUTHORIZED))
    (dividend-info (unwrap! (map-get? property-dividends { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
    (user-claim-info (default-to { last-claimed-block: u0 } (map-get? user-dividend-claims { property-id: property-id, user: tx-sender })))
    (claimable-amount (* (get token-amount user-ownership) (get dividend-per-token dividend-info)))
  )
    (asserts! (get is-active property) ERR_PROPERTY_NOT_ACTIVE)
    (asserts! (> (get token-amount user-ownership) u0) ERR_UNAUTHORIZED)
    (asserts! (> (get last-distribution dividend-info) (get last-claimed-block user-claim-info)) ERR_INVALID_AMOUNT)
    
    (map-set user-dividend-claims
      { property-id: property-id, user: tx-sender }
      { last-claimed-block: stacks-block-height }
    )
    
    (try! (stx-transfer? claimable-amount (get owner property) tx-sender))
    (ok claimable-amount)
  )
)

(define-public (update-property-status (property-id uint) (is-active bool))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get owner property)) ERR_UNAUTHORIZED)
    
    (map-set properties
      { property-id: property-id }
      (merge property { is-active: is-active })
    )
    
    (ok true)
  )
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq tx-sender sender) (is-eq contract-caller sender)) ERR_UNAUTHORIZED)
    (ft-transfer? propchain-token amount sender recipient)
  )
)

(define-read-only (get-name)
  (ok (var-get token-name))
)

(define-read-only (get-symbol)
  (ok (var-get token-symbol))
)

(define-read-only (get-decimals)
  (ok (var-get token-decimals))
)

(define-read-only (get-balance (user principal))
  (ok (ft-get-balance propchain-token user))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply propchain-token))
)

(define-read-only (get-token-uri (token-id (optional uint)))
  (ok none)
)

(define-read-only (get-property (property-id uint))
  (map-get? properties { property-id: property-id })
)

(define-read-only (get-property-ownership (property-id uint) (owner principal))
  (map-get? property-ownership { property-id: property-id, owner: owner })
)

(define-read-only (get-property-proposal (property-id uint) (proposal-id uint))
  (map-get? property-proposals { property-id: property-id, proposal-id: proposal-id })
)

(define-read-only (get-user-vote (property-id uint) (proposal-id uint) (voter principal))
  (map-get? user-votes { property-id: property-id, proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-property-dividends (property-id uint))
  (map-get? property-dividends { property-id: property-id })
)

(define-read-only (get-user-dividend-claims (property-id uint) (user principal))
  (map-get? user-dividend-claims { property-id: property-id, user: user })
)

(define-read-only (calculate-ownership-percentage (property-id uint) (owner principal))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) ERR_PROPERTY_NOT_FOUND))
    (ownership (default-to { token-amount: u0 } (map-get? property-ownership { property-id: property-id, owner: owner })))
  )
    (if (> (get total-tokens property) u0)
      (ok (/ (* (get token-amount ownership) u10000) (get total-tokens property)))
      ERR_INVALID_AMOUNT
    )
  )
)

(define-read-only (get-property-count)
  (- (var-get next-property-id) u1)
)

(define-private (calculate-voting-power (property-id uint) (voter principal))
  (let (
    (ownership (default-to { token-amount: u0 } (map-get? property-ownership { property-id: property-id, owner: voter })))
  )
    (get token-amount ownership)
  )
)

(define-private (validate-property-exists (property-id uint))
  (is-some (map-get? properties { property-id: property-id }))
)

(define-private (is-property-owner (property-id uint) (user principal))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) false))
  )
    (is-eq (get owner property) user)
  )
)

(define-private (has-property-tokens (property-id uint) (user principal))
  (let (
    (ownership (default-to { token-amount: u0 } (map-get? property-ownership { property-id: property-id, owner: user })))
  )
    (> (get token-amount ownership) u0)
  )
)
