#!/usr/bin/env sbcl --script
;;;; Common Lisp Concurrent Log Anomaly Counter
;;;; Uses SBCL threads for parallel processing

(require :sb-posix)

;;; Helper function to check if character is alphanumeric
(defun is-alnum (char)
  (or (char<= #\0 char #\9)
      (char<= #\A char #\Z)
      (char<= #\a char #\z)))

;;; Check if word exists with word boundaries in line
(defun contains-word (line word)
  (let ((word-len (length word))
        (line-len (length line)))
    (when (and (> word-len 0) (>= line-len word-len))
      (loop with start = 0
            for pos = (search word line :start2 start)
            while pos
            do (let* ((before (if (> pos 0) (1- pos) nil))
                      (after (+ pos word-len))
                      (start-ok (or (null before) (not (is-alnum (char line before)))))
                      (end-ok (or (>= after line-len) (not (is-alnum (char line after))))))
                 (when (and start-ok end-ok)
                   (return-from contains-word t))
                 (setf start (1+ pos)))
            finally (return nil)))))

;;; Process a chunk of lines
(defun process-chunk (lines)
  (let ((errors 0)
        (warnings 0))
    (dolist (line lines)
      (cond
        ((and (find #\E line) (contains-word line "ERROR"))
         (incf errors))
        ((and (find #\W line) (contains-word line "WARN"))
         (incf warnings))))
    (list errors warnings)))

;;; Worker thread function
(defun worker-thread (lines-chunk result-lock result-errors result-warnings)
  (let* ((result (process-chunk lines-chunk))
         (chunk-errors (first result))
         (chunk-warnings (second result)))
    (sb-thread:with-mutex (result-lock)
      (incf result-errors chunk-errors)
      (incf result-warnings chunk-warnings))))

;;; Main processing function
(defun process-log-file (filepath)
  (let ((lines '()))
    ;; Read all lines
    (with-open-file (stream filepath :direction :input)
      (loop for line = (read-line stream nil)
            while line
            do (push line lines)))
    
    (setf lines (nreverse lines))
    
    (if (null lines)
        (values 0 0)
        (let* ((num-threads (min 4 (length lines)))
               (chunk-size (ceiling (length lines) num-threads))
               (result-lock (sb-thread:make-mutex :name "result-lock"))
               (result-errors 0)
               (result-warnings 0)
               (threads '()))
          
          ;; Create and start threads
          (loop for i from 0 below num-threads
                for start = (* i chunk-size)
                when (< start (length lines))
                do (let* ((end (min (+ start chunk-size) (length lines)))
                          (chunk (subseq lines start end)))
                     (push (sb-thread:make-thread
                            (lambda ()
                              (worker-thread chunk result-lock result-errors result-warnings))
                            :name (format nil "worker-~d" i))
                           threads)))
          
          ;; Wait for all threads
          (dolist (thread threads)
            (sb-thread:join-thread thread))
          
          (values result-errors result-warnings)))))

;;; Main entry point
(defun main ()
  (let ((args sb-ext:*posix-argv*))
    (unless (= (length args) 2)
      (format *error-output* "Usage: sbcl --script solution.lisp <logfile>~%")
      (sb-ext:exit :code 1))
    
    (let ((logfile (second args)))
      ;; Check if file exists
      (unless (probe-file logfile)
        (format *error-output* "Error: File not found: ~a~%" logfile)
        (sb-ext:exit :code 1))
      
      (multiple-value-bind (errors warnings)
          (process-log-file logfile)
        (let ((total (+ errors warnings)))
          ;; Output JSON
          (format t "{\"errors\":~d,\"warnings\":~d,\"total\":~d}~%" errors warnings total)
          (sb-ext:exit :code 0))))))

;;; Run main
(main)
