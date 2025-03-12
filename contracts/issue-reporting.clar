;; Issue Reporting Contract
;; Allows citizens to log community problems

(define-data-var issue-counter uint u0)

(define-map issues
  { id: uint }
  {
    reporter: principal,
    title: (string-ascii 64),
    description: (string-ascii 256),
    location: (string-ascii 64),
    category: (string-ascii 32),
    timestamp: uint,
    status: (string-ascii 16)
  }
)

(define-map issue-attachments
  { issue-id: uint, attachment-id: uint }
  {
    attachment-type: (string-ascii 16),
    attachment-url: (string-ascii 128)
  }
)

;; Report a new issue
(define-public (report-issue
                (title (string-ascii 64))
                (description (string-ascii 256))
                (location (string-ascii 64))
                (category (string-ascii 32)))
  (let
    ((new-id (+ (var-get issue-counter) u1)))

    ;; Update counter
    (var-set issue-counter new-id)

    ;; Store issue data
    (ok (map-set issues
      { id: new-id }
      {
        reporter: tx-sender,
        title: title,
        description: description,
        location: location,
        category: category,
        timestamp: block-height,
        status: "reported"
      }
    ))
  )
)

;; Add attachment to an issue
(define-public (add-attachment
                (issue-id uint)
                (attachment-id uint)
                (attachment-type (string-ascii 16))
                (attachment-url (string-ascii 128)))
  (let
    ((issue (default-to
              { reporter: tx-sender, title: "", description: "", location: "", category: "", timestamp: u0, status: "" }
              (map-get? issues { id: issue-id }))))

    ;; Only the original reporter can add attachments
    (asserts! (is-eq tx-sender (get reporter issue)) (err u1))

    ;; Store attachment data
    (ok (map-set issue-attachments
      { issue-id: issue-id, attachment-id: attachment-id }
      {
        attachment-type: attachment-type,
        attachment-url: attachment-url
      }
    ))
  )
)

;; Update an issue
(define-public (update-issue
                (issue-id uint)
                (title (string-ascii 64))
                (description (string-ascii 256))
                (location (string-ascii 64))
                (category (string-ascii 32)))
  (let
    ((issue (default-to
              { reporter: tx-sender, title: "", description: "", location: "", category: "", timestamp: u0, status: "" }
              (map-get? issues { id: issue-id }))))

    ;; Only the original reporter can update the issue
    (asserts! (is-eq tx-sender (get reporter issue)) (err u1))

    ;; Status must still be "reported" to update
    (asserts! (is-eq (get status issue) "reported") (err u2))

    ;; Update issue data
    (ok (map-set issues
      { id: issue-id }
      (merge issue {
        title: title,
        description: description,
        location: location,
        category: category
      })
    ))
  )
)

;; Get issue details
(define-read-only (get-issue (issue-id uint))
  (map-get? issues { id: issue-id })
)

;; Get attachment details
(define-read-only (get-attachment (issue-id uint) (attachment-id uint))
  (map-get? issue-attachments { issue-id: issue-id, attachment-id: attachment-id })
)

;; Check if issue exists
(define-read-only (issue-exists (issue-id uint))
  (is-some (map-get? issues { id: issue-id }))
)

