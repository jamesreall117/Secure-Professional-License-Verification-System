;; license-issuance.clar
;; This contract records professional qualifications and approvals

(define-constant err-not-authorized (err u100))
(define-constant err-license-exists (err u101))
(define-constant err-license-not-found (err u102))

;; Define license data structure
(define-map licenses
  { license-id: (string-ascii 20), professional-id: principal }
  {
    authority: principal,
    profession: (string-ascii 50),
    issue-date: uint,
    expiry-date: uint,
    qualifications: (string-ascii 200)
  }
)

;; Define license ID to professional mapping for lookup
(define-map license-id-to-professional
  { license-id: (string-ascii 20) }
  { professional-id: principal }
)

;; Contract for authority validation
(define-trait authority-trait
  (
    (is-authority (principal) (response bool uint))
  )
)

;; Issue a new license
(define-public (issue-license
    (license-id (string-ascii 20))
    (professional-id principal)
    (profession (string-ascii 50))
    (expiry-date uint)
    (qualifications (string-ascii 200))
    (authority-contract <authority-trait>))
  (let
    ((authority-check (contract-call? authority-contract is-authority tx-sender)))
    (begin
      (asserts! (is-ok authority-check) err-not-authorized)
      (asserts! (is-eq (unwrap-panic authority-check) true) err-not-authorized)
      (asserts! (is-none (map-get? license-id-to-professional { license-id: license-id })) err-license-exists)

      (map-set license-id-to-professional
        { license-id: license-id }
        { professional-id: professional-id }
      )

      (map-set licenses
        { license-id: license-id, professional-id: professional-id }
        {
          authority: tx-sender,
          profession: profession,
          issue-date: block-height,
          expiry-date: expiry-date,
          qualifications: qualifications
        }
      )
      (ok true)
    )
  )
)

;; Get license details
(define-read-only (get-license-details (license-id (string-ascii 20)))
  (let
    ((professional-data (map-get? license-id-to-professional { license-id: license-id })))
    (if (is-some professional-data)
      (let
        ((professional (get professional-id (unwrap-panic professional-data))))
        (map-get? licenses { license-id: license-id, professional-id: professional })
      )
      none
    )
  )
)

;; Check if a license exists
(define-read-only (license-exists (license-id (string-ascii 20)))
  (is-some (map-get? license-id-to-professional { license-id: license-id }))
)
