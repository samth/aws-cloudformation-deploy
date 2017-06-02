#! /usr/bin/env racket
#lang at-exp curly-fn racket

(require racket/runtime-path
         json)

#|exports|#
(provide make-aws-cli-filepath
         make-tags
         make-aws-parameters
         make-stack-policy-path
         make-aws-cli-arguments
         update-or-create-stack
         )

#|filepath functions|#
#|how will the scripts that reference this file get the correct dir path? as written, these return the dir of this file :(|#
(define-runtime-path abnormal-script-dir ".")

(define script-dir
  (normalize-path abnormal-script-dir))

(define (make-aws-cli-filepath filepath)
  @~a{file://@(path->complete-path (build-path filepath))})

#|build aws command functions|#
(define (make-tags #:application application
                   #:squad squad
                   #:environment environment)
  (list "--tags"
        @~a{Key=cj,Value=application=@application}
        @~a{Key=cj,Value=squad=@squad}
        @~a{Key=cj,Value=environment=@environment}))

(define (make-aws-parameter key
                            value)
  @~a{ParameterKey=@key,ParameterValue=@value})

(define (make-aws-parameters parameter-dict)
  (flatten (list "--parameters"
                 (map #{make-aws-parameter (car %) (cdr %)}
                      parameter-dict))))

(define (make-stack-policy-path stack-policy-filepath)
  (list "--stack-policy-body"
        @(make-aws-cli-filepath stack-policy-filepath)))

(define/contract (make-aws-cli-arguments command
                                         stack-name
                                         template-filepath
                                         application
                                         squad
                                         environment
                                         #:param-dict [param-dict (list)]
                                         #:stack-policy-filepath [stack-policy-filepath #f])
  (-> (or/c "create-stack" "update-stack")
      string?
      path-string?
      string?
      string?
      string?
      #:param-dict dict?
      #:stack-policy-filepath (or/c path-string? #f)
      list?)
  (flatten (list command
                 "--stack-name" stack-name
                 "--template-body" (make-aws-cli-filepath template-filepath)
                 "--capabilities" "CAPABILITY_IAM"
                 (make-tags #:application application
                            #:squad squad
                            #:environment environment)
                 (make-aws-parameters param-dict)
                 (if stack-policy-filepath
                     (make-stack-policy-path stack-policy-filepath)
                     (list)))))

(define (update-or-create-stack command
                                stack-name
                                template-filepath
                                application
                                squad
                                environment
                                param-dict
                                [stack-policy-filepath #f])
  (apply system*
         (find-executable-path "aws")
         "cloudformation"
         (make-aws-cli-arguments command
                                 stack-name
                                 template-filepath
                                 application
                                 squad
                                 environment
                                 #:param-dict param-dict
                                 #:stack-policy-filepath stack-policy-filepath)))

(define (stack-outputs stack-name)
  (let ([output (string->jsexpr
                 (with-output-to-string
                     (λ ()
                       (system* (find-executable-path "aws")
                                "cloudformation" "describe-stacks"
                                "--stack-name" stack-name
                                "--output" "json"
                                ))))]
        [transform #{cons (hash-ref % 'OutputKey) (hash-ref % 'OutputValue)}])
    (map transform
         (hash-ref (first (hash-ref output 'Stacks)) 'Outputs))))
 
