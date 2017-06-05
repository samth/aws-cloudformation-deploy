#lang racket

(require rackunit
         "../src/core.rkt")

(test-case
 "make-aws-cli-filepath"
 (check-equal? (make-aws-cli-filepath "/testpath/test-template.yaml")
              "file:///testpath/test-template.yaml"))

(test-case
 "make-tags"
 (check-equal? (make-tags
               #:application "test-app"
               #:squad "test-squad"
               #:environment "test-env")
              (list "--tags" "Key=cj,Value=application=test-app" "Key=cj,Value=squad=test-squad" "Key=cj,Value=environment=test-env")))

(test-case
 "make-aws-parameters single param"
 (check-equal? (make-aws-parameters (list (cons "test-key" "test-val")))
              (list "--parameters" "ParameterKey=test-key,ParameterValue=test-val")))

(test-case
 "make-aws-parameters multi-param"
 (check-equal? (make-aws-parameters (list (cons "test-key" "test-val") (cons "test-key-1" "test-val-1")))
              (list "--parameters" "ParameterKey=test-key,ParameterValue=test-val" "ParameterKey=test-key-1,ParameterValue=test-val-1")))

(test-case
 "make-stack-policy-path"
 (check-equal? (make-stack-policy-path "/Users/test-user/project/test-policy.json")
              (list "--stack-policy-body" "file:///Users/test-user/project/test-policy.json")))

(test-case
 "make-aws-cli-arguments"
 (check-equal? (make-aws-cli-arguments "create-stack"
                                      "test-stack"
                                      "/test-path/to-template.yaml"
                                      "test-app"
                                      "test-squad"
                                      "test-env"
                                      #:param-dict (list (cons "test-key" "test-val") (cons "test-key2" "test-val2"))
                                      #:stack-policy-filepath "/test-path/to-stack-policy.json")
              (list "create-stack"
                    "--stack-name" "test-stack"
                    "--template-body" "file:///test-path/to-template.yaml"
                    "--capabilities" "CAPABILITY_IAM"
                    "--tags" "Key=cj,Value=application=test-app" "Key=cj,Value=squad=test-squad" "Key=cj,Value=environment=test-env"
                    "--parameters" "ParameterKey=test-key,ParameterValue=test-val" "ParameterKey=test-key2,ParameterValue=test-val2"
                    "--stack-policy-body" "file:///test-path/to-stack-policy.json")))

