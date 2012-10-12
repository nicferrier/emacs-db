;;; tests for the emacs db.

(require 'cl)
(require 'ert)
(require 'db)
(require 'kv)

(ert-deftest db-get ()
  "Test the database interface and the hash implementation."
  ;; Make a hash-db with no filename
  (let ((db (db-make '(db-hash))))
    (should-not (db-get "test-key" db))
    (db-put "test-key" 321 db)
    (should
     (equal
      321
      (db-get "test-key" db)))))

(ert-deftest db-put ()
  "Test the put interface."
  (let ((db (db-make '(db-hash))))
    (should-not (db-get "test-key" db))
    (should
     (equal
      '("1" "2" "3")
      (db-put "test-key" '("1" "2" "3") db)))))

(ert-deftest db-query ()
  "Test the query interfce."
  (let ((db (db-make '(db-hash))))
    (db-put "test001"
            '(("username" . "test001")
              ("title" . "Miss")
              ("surname" . "Test")) db)
    (db-put "test002"
            '(("username" . "test002")
              ("title" . "Mr")
              ("surname" . "Test")) db)
    (should
     (equal
      '(("test001"
         ("username" . "test001")
         ("title" . "Miss")
         ("surname" . "Test")))
      (db-map 'kvidentity db '(= "username" "test001"))))))

(ert-deftest db-query-deep ()
  "Test the query interface with a dotted query."
  (let ((db (db-make '(db-hash :query-equal kvdotassoc=))))
    (db-put "test001"
            '(("username" . "test001")
              ("details" . (("title" . "Miss")
                            ("surname" . "Test")))) db)
    (db-put "test002"
            '(("username" . "test002")
              ("details" .(("title" . "Mr")
                           ("surname" . "Tester")))) db)
    (should
     (equal
      '(("test001"
         ("username" . "test001")
         ("details" . (("title" . "Miss")
                       ("surname" . "Test")))))
      (db-query db '(= "details.surname" "Test"))))))


(ert-deftest db-hash--save ()
  "Test the saving of a hash db."
  (unwind-protect
       (progn
         (let ((db (db-make
                    ;; You shouldn't use an extension but let elnode deal
                    ;; with it.
                    '(db-hash :filename "/tmp/test-db"))))
           ;; Override the save so it does nothing from put
           (flet ((db-hash--save (db)
                    t))
             (db-put 'test1 "value1" db)
             (db-put 'test2 "value2" db))
           ;; And now save
           (db-hash--save db))
         ;; And now load in a different scope
         (let ((db (db-make
                    '(db-hash :filename "/tmp/test-db"))))
           (should
            (equal "value1"
                   (db-get 'test1 db)))))
    (delete-file "/tmp/test-db.elc")))

(ert-deftest db-filter ()
  "Test the filtering."
  (let ((db (db-make
             '(db-hash :filename "/tmp/test-db"))))
    (db-put
     "test001"
     '(("uid" . "test001")
       ("fullname" . "test user 1"))
     db)
    (db-put
     "test002"
     '(("uid" . "test002")
       ("fullname" . "test user 2"))
     db)
    (db-put
     "test003"
     '(("uid" . "test001")
       ("fullname" . "test user 1"))
     db)
    (flet ((filt (key value)
             (cdr (assoc "fullname" value))))
      (let ((filtered
             (db-make
              `(db-filter
                :source ,db
                :filter filt))))
        (plist-get filtered :source)
        (should
         (equal (db-get "test002" filtered) "test user 2"))))))

(provide 'db-tests)

;;; db-tests.el ends here
