;;; -*- Mode: Lisp; Package: COMMON-LISP-USER -*-

;;;  (c) copyright 2005 by
;;;           Aleksandar Bakic (a_bakic@yahoo.com)
;;;  (c) copyright 2006 by
;;;           Troels Henriksen (athas@sigkill.dk)

;;; This library is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU Library General Public
;;; License as published by the Free Software Foundation; either
;;; version 2 of the License, or (at your option) any later version.
;;;
;;; This library is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Library General Public License for more details.
;;;
;;; You should have received a copy of the GNU Library General Public
;;; License along with this library; if not, write to the
;;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;;; Boston, MA  02111-1307  USA.

(cl:in-package :drei-tests)

(def-suite core-tests :description "The test suite for
DREI-CORE related tests.")

(in-suite core-tests)

(test downcase-word
  (with-buffer (buffer)
    (downcase-word (point buffer) (syntax buffer) 1)
    (is (string= (buffer-contents buffer) "")))
  (with-buffer (buffer :initial-contents "CLI MA CS CLIMACS")
    (let ((m (clone-mark (low-mark buffer) :right)))
      (setf (offset m) 0)
      (downcase-word m (syntax buffer) 3)
      (is (string= (buffer-contents buffer)
                   "cli ma cs CLIMACS"))
      (is (= (offset m) 9)))))

(test upcase-word
  (with-buffer (buffer)
    (upcase-word (point buffer) (syntax buffer) 1)
    (is (string= (buffer-contents buffer) "")))
  (with-buffer (buffer :initial-contents "cli ma cs climacs")
    (let ((m (clone-mark (low-mark buffer) :right)))
      (setf (offset m) 0)
      (upcase-word m (syntax buffer) 3)
      (is (string= (buffer-contents buffer)
                   "CLI MA CS climacs"))
      (is (= (offset m) 9)))))

(test capitalize-word
  (with-buffer (buffer)
    (capitalize-word (point buffer) (syntax buffer) 1)
    (is (string= (buffer-contents buffer) "")))
  (with-buffer (buffer :initial-contents "cli ma cs climacs")
    (let ((m (clone-mark (low-mark buffer) :right)))
      (setf (offset m) 0)
      (capitalize-word m (syntax buffer) 3)
      (is (string= (buffer-contents buffer)
                   "Cli Ma Cs climacs"))
      (is (= (offset m) 9)))))

(test possibly-fill-line
  (with-drei-environment ()
    (possibly-fill-line)
    (is (string= (buffer-contents) "")))
  (with-drei-environment
      (:initial-contents "Very long line, this should be filled, if auto-fill is on.")

    (setf (auto-fill-column *current-window*) 200
          (auto-fill-mode *current-window*) nil
          (offset *current-point*) (size *current-buffer*))
    (possibly-fill-line)
    (is (string= (buffer-contents)
                 "Very long line, this should be filled, if auto-fill is on."))
    
    (setf (auto-fill-mode *current-window*) t)
    (possibly-fill-line)
    (is (string= (buffer-contents)
                 "Very long line, this should be filled, if auto-fill is on."))
    
    (setf (auto-fill-column *current-window*) 20)
    (possibly-fill-line)
    (is (string= (buffer-contents)
                 "Very long line,
this should be
filled, if auto-fill
is on."))))

(test back-to-indentation
  (with-drei-environment
      (:initial-contents #.(format nil "  ~A Foobar!" #\Tab))
    (end-of-buffer *current-point*)
    (back-to-indentation *current-point* *current-syntax*)
    (is (= (offset *current-point*) 4))))

(test insert-character
  ;; Test:
  ;; - Overwriting
  ;; - Auto-filling
  ;; - Standard insertion
  (with-drei-environment ()
    (setf (auto-fill-mode *current-window*) nil
          (overwrite-mode *current-window*) nil)
    (insert-character #\a)
    (is (string= (buffer-contents) "a"))
    (insert-character #\b)
    (is (string= (buffer-contents) "ab"))
    (backward-object *current-point* 2)
    (insert-character #\t)
    (is (string= (buffer-contents) "tab"))
    (setf (overwrite-mode *current-window*) t)
    (insert-character #\i)
    (insert-character #\p)
    (is (string= (buffer-contents) "tip"))
    ;; TODO: Also test dynamic abbreviations?
    ))

(test delete-horizontal-space
  (with-drei-environment (:initial-contents "     foo")
    (setf (offset *current-point*) 3)
    (delete-horizontal-space *current-point* *current-syntax*)
    (is (string= (buffer-contents) "foo"))
    (insert-sequence *current-point* "     ")
    (setf (offset *current-point*) 3)
    (delete-horizontal-space *current-point* *current-syntax* t)
    (is (string= (buffer-contents) "  foo"))
    (delete-horizontal-space *current-point* *current-syntax*)
    (is (string= (buffer-contents) "foo"))
    (delete-horizontal-space *current-point* *current-syntax*)
    (is (string= (buffer-contents) "foo"))))

(test indent-current-line
  (with-drei-environment (:initial-contents "Foo bar baz
  Quux")
    (indent-current-line *current-window* *current-point*)
    (is (string= (buffer-contents)
                 "Foo bar baz
  Quux"))
    (setf (offset *current-point*) 12)
    (indent-current-line *current-window* *current-point*)
    (is (string= (buffer-contents)
                 "Foo bar baz
Quux"))))

(test insert-pair
  (with-drei-environment ()
    (insert-pair *current-mark* *current-syntax*)
    (buffer-is "()")
    (beginning-of-buffer *current-point*)
    (insert-pair *current-point* *current-syntax* 0 #\[ #\])
    (buffer-is "[] ()")))

(test goto-position
  (with-drei-environment (:initial-contents "foobarbaz")
    (goto-position *current-point* 5)
    (is (= (offset *current-point*) 5))))

(test goto-line
  (with-drei-environment (:initial-contents "First line
Second line
Third line")
    (goto-line *current-point* 1)
    (is (= (line-number *current-point*) 0))
    (is (= (offset *current-point*) 0))
    (goto-line *current-point* 2)
    (is (= (line-number *current-point*) 1))
    (is (= (offset *current-point*) 11))
    (goto-line *current-point* 3)
    (is (= (line-number *current-point*) 2))
    (is (= (offset *current-point*) 23))
    (goto-line *current-point* 4)
    (is (= (line-number *current-point*) 2))
    (is (= (offset *current-point*) 23))))

(test replace-one-string
  (with-drei-environment (:initial-contents "Drei Climacs Drei")
    (replace-one-string *current-point* 17 "foo bar" nil)
    (buffer-is "foo bar"))
  (with-drei-environment (:initial-contents "drei climacs drei")
    (replace-one-string *current-point* 17 "foo bar" t)
    (buffer-is "foo bar"))
  (with-drei-environment (:initial-contents "Drei Climacs Drei")
    (replace-one-string *current-point* 17 "foo bar" t)
    (buffer-is "Foo Bar"))
  (with-drei-environment (:initial-contents "DREI CLIMACS DREI")
    (replace-one-string *current-point* 17 "foo bar" t)
    (buffer-is "FOO BAR")))

(test downcase-word
  (with-drei-environment (:initial-contents "Drei Climacs Drei")
    (downcase-word *current-point* *current-syntax* 1)
    (buffer-is "drei Climacs Drei")
    (downcase-word *current-point* *current-syntax* 1)
    (buffer-is "drei climacs Drei")
    (downcase-word *current-point* *current-syntax* 1)
    (buffer-is "drei climacs drei"))
  (with-drei-environment (:initial-contents "Drei Climacs Drei")
    (downcase-word *current-point* *current-syntax* 0)
    (buffer-is "Drei Climacs Drei"))
  (with-drei-environment (:initial-contents "Drei Climacs Drei")
    (downcase-word *current-point* *current-syntax* 2)
    (buffer-is "drei climacs Drei"))
  (with-drei-environment (:initial-contents "Drei Climacs Drei")
    (downcase-word *current-point* *current-syntax* 3)
    (buffer-is "drei climacs drei")))

(test upcase-word
  (with-drei-environment (:initial-contents "Drei Climacs Drei")
    (upcase-word *current-point* *current-syntax* 1)
    (buffer-is "DREI Climacs Drei")
    (upcase-word *current-point* *current-syntax* 1)
    (buffer-is "DREI CLIMACS Drei")
    (upcase-word *current-point* *current-syntax* 1)
    (buffer-is "DREI CLIMACS DREI"))
  (with-drei-environment (:initial-contents "Drei Climacs Drei")
    (upcase-word *current-point* *current-syntax* 0)
    (buffer-is "Drei Climacs Drei"))
  (with-drei-environment (:initial-contents "Drei Climacs Drei")
    (upcase-word *current-point* *current-syntax* 2)
    (buffer-is "DREI CLIMACS Drei"))
  (with-drei-environment (:initial-contents "Drei Climacs Drei")
    (upcase-word *current-point* *current-syntax* 3)
    (buffer-is "DREI CLIMACS DREI")))

(test capitalize-word
  (with-drei-environment (:initial-contents "drei climacs drei")
    (capitalize-word *current-point* *current-syntax* 1)
    (buffer-is "Drei climacs drei")
    (capitalize-word *current-point* *current-syntax* 1)
    (buffer-is "Drei Climacs drei")
    (capitalize-word *current-point* *current-syntax* 1)
    (buffer-is "Drei Climacs Drei"))
  (with-drei-environment (:initial-contents "drei climacs drei")
    (capitalize-word *current-point* *current-syntax* 0)
    (buffer-is "drei climacs drei"))
  (with-drei-environment (:initial-contents "drei climacs drei")
    (capitalize-word *current-point* *current-syntax* 2)
    (buffer-is "Drei Climacs drei"))
  (with-drei-environment (:initial-contents "drei climacs drei")
    (capitalize-word *current-point* *current-syntax* 3)
    (buffer-is "Drei Climacs Drei")))

(test indent-region
  ;; FIXME: Sadly, we can't test this function, because it requires a
  ;; CLIM pane.
  )

(test fill-line
  (flet ((fill-it (fill-column)
           (let ((tab-width (tab-space-count (stream-default-view *current-window*))))
             (fill-line *current-point*
                        (lambda (mark)
                          (syntax-line-indentation mark tab-width *current-syntax*))
                        fill-column tab-width (syntax *current-buffer*)))))
    (with-drei-environment (:initial-contents "climacs  climacs  climacs  climacs")
      (let ((m (clone-mark (low-mark *current-buffer*) :right)))
        (setf (offset m) 25)
        (fill-line m #'(lambda (m) (declare (ignore m)) 8) 10 8 *current-syntax*)
        (is (= (offset m) 25))
        (buffer-is "climacs
	climacs
	climacs  climacs")))
    (with-drei-environment (:initial-contents "climacs  climacs  climacs  climacs")
      (let ((m (clone-mark (low-mark *current-buffer*) :right)))
        (setf (offset m) 25)
        (fill-line m #'(lambda (m) (declare (ignore m)) 8) 10 8 *current-syntax* nil)
        (is (= (offset m) 27))
        (buffer-is "climacs 
	climacs 
	climacs  climacs")))
    (with-drei-environment (:initial-contents #.(format nil "climacs~Aclimacs~Aclimacs~Aclimacs"
                                                     #\Tab #\Tab #\Tab))
      (let ((m (clone-mark (low-mark *current-buffer*) :left)))
        (setf (offset m) 25)
        (fill-line m #'(lambda (m) (declare (ignore m)) 8) 10 8 *current-syntax*)
        (is (= (offset m) 27))
        (buffer-is "climacs
	climacs
	climacs	climacs")))
    (with-drei-environment (:initial-contents #.(format nil "climacs~Aclimacs~Aclimacs~Aclimacs"
                                                     #\Tab #\Tab #\Tab))
      (let ((m (clone-mark (low-mark *current-buffer*) :left)))
        (setf (offset m) 25)
        (fill-line m #'(lambda (m) (declare (ignore m)) 8) 10 8 *current-syntax*)
        (is (= (offset m) 27))
        (buffer-is "climacs
	climacs
	climacs	climacs")))
    (with-drei-environment (:initial-contents "c l i m a c s")
      (let ((m (clone-mark (low-mark *current-buffer*) :right)))
        (setf (offset m) 1)
        (fill-line m #'(lambda (m) (declare (ignore m)) 8) 0 8 *current-syntax*)
        (is (= (offset m) 1))
        (buffer-is "c l i m a c s")))
    (with-drei-environment (:initial-contents "c l i m a c s")
      (let ((m (clone-mark (low-mark *current-buffer*) :right)))
        (setf (offset m) 1)
        (fill-line m #'(lambda (m) (declare (ignore m)) 8) 0 8 *current-syntax* nil)
        (is (= (offset m) 1))
        (buffer-is "c l i m a c s")))
    (with-drei-environment ()
      (fill-it 80)
      (buffer-is ""))
    (with-drei-environment
        (:initial-contents "Very long line, this should certainly be filled, if everything works")
      (end-of-buffer *current-point*)
      (fill-it 200)
      (buffer-is "Very long line, this should certainly be filled, if everything works")
      (fill-it 20)
      (buffer-is "Very long line,
this should
certainly be filled,
if everything works"))))

(test fill-region
  (flet ((fill-it (fill-column)
           (let ((tab-width (tab-space-count (stream-default-view *current-window*))))
             (fill-region *current-point* *current-mark* 
                          (lambda (mark)
                            (syntax-line-indentation mark tab-width *current-syntax*))
                          fill-column tab-width *current-syntax*))))
    (with-drei-environment
        (:initial-contents "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

What, you thought I would write something this long myself? Not a chance. Though this line is growing by a fair bit too, I better test it as well.")
      (end-of-line *current-mark*)
      (fill-it 80)
      (buffer-is "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor
incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu
fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.

What, you thought I would write something this long myself? Not a chance. Though this line is growing by a fair bit too, I better test it as well.")
      (end-of-buffer *current-mark*)
      (forward-paragraph *current-point* *current-syntax* 2 nil)
      (backward-paragraph *current-point* *current-syntax* 1)
      (fill-it 80)
      (buffer-is "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor
incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu
fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.

What, you thought I would write something this long myself? Not a chance.
Though this line is growing by a fair bit too, I better test it as well."))))

(test indent-line
  (dolist (stick-to '(:left :right))
    (with-drei-environment ()
      (buffer-is ""))
    (with-drei-environment (:initial-contents "I am to be indented")
      (indent-line (clone-mark *current-point* stick-to) 11 nil)
      (buffer-is "           I am to be indented"))
    (with-drei-environment (:initial-contents "I am to be indented")
      (indent-line (clone-mark *current-point* stick-to) 11 2)
      (buffer-is #. (format nil "~A~A~A~A~A I am to be indented"
                            #\Tab #\Tab #\Tab #\Tab #\Tab)))))

(test delete-indentation
  (with-drei-environment (:initial-contents "")
    (delete-indentation *current-syntax* *current-point*)
    (buffer-is ""))
  (with-drei-environment (:initial-contents "Foo")
    (delete-indentation *current-syntax* *current-point*)
    (buffer-is "Foo"))
  (with-drei-environment (:initial-contents " Foo")
    (delete-indentation *current-syntax* *current-point*)
    (buffer-is "Foo"))
  (with-drei-environment (:initial-contents "   	Foo  ")
    (delete-indentation *current-syntax* *current-point*)
    (buffer-is "Foo  "))
  (with-drei-environment (:initial-contents "   Foo  
  Bar
 Baz")
    (forward-line *current-point* *current-syntax*)
    (delete-indentation *current-syntax* *current-point*)
    (buffer-is "   Foo  
Bar
 Baz")))

(test set-syntax
  (dolist (syntax-designator `("Lisp" drei-lisp-syntax::lisp-syntax
                                      ,(find-class 'drei-lisp-syntax::lisp-syntax)))
    (with-drei-environment ()
      (set-syntax *current-buffer* syntax-designator)
      (is (not (eq *current-syntax* (syntax *current-buffer*))))
      (is (typep (syntax *current-buffer*) 'drei-lisp-syntax::lisp-syntax)))))

(test with-narrowed-buffer
  (with-drei-environment (:initial-contents "foo bar baz quux")
    (setf (offset *current-point*) 1
          (offset *current-mark*) (1- (size *current-buffer*)))
    (let ((mark1 (clone-mark *current-point* :left))
          (mark2 (clone-mark *current-mark* :right)))
      (forward-object mark1)
      (backward-object mark2)
      (dolist (low (list 2 mark1))
        (dolist (high (list (- (size *current-buffer*) 2) mark2))
          (with-narrowed-buffer (*current-window* low high t)
            (is (= (offset *current-point*) 2))
            (is (= (offset *current-mark*) (- (size *current-buffer*) 2)))))))))
