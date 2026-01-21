;; Library Book Lending Contract
;; Decentralized library management and book lending system

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-not-available (err u102))
(define-constant err-already-borrowed (err u103))
(define-constant err-not-borrowed (err u104))
(define-constant err-invalid-input (err u105))
(define-constant err-overdue (err u106))
(define-constant err-already-reserved (err u107))
(define-constant err-no-reservation (err u108))
(define-constant err-rating-exists (err u109))
(define-constant max-loan-period u1000)