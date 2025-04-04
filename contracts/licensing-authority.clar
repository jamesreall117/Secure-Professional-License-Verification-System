;; licensing-authority.clar
;; This contract validates legitimate regulatory bodies

(define-data-var contract-owner principal tx-sender)

;; Map to store authorized licensing authorities
(define-map licensing-authorities principal bool)

;; Error codes
(define-constant err-not-authorized (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner)))

;; Register a new licensing authority
(define-public (register-authority (authority principal))
  (begin
    (asserts! (is-contract-owner) err-not-authorized)
    (asserts! (is-none (map-get? licensing-authorities authority)) err-already-registered)
    (ok (map-set licensing-authorities authority true))))

;; Remove a licensing authority
(define-public (remove-authority (authority principal))
  (begin
    (asserts! (is-contract-owner) err-not-authorized)
    (asserts! (is-some (map-get? licensing-authorities authority)) err-not-found)
    (ok (map-delete licensing-authorities authority))))

;; Check if an authority is registered
(define-read-only (is-authority (authority principal))
  (default-to false (map-get? licensing-authorities authority)))

;; Transfer ownership of the contract
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) err-not-authorized)
    (ok (var-set contract-owner new-owner))))
