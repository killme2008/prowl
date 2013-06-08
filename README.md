# prowl

A Clojure library designed to profile clojure program.

## Usage

Add it to project.clj dependencies:

	[prowl "0.1.0-SNAPSHOT"]
	
Use it in your clojure code:

```clojure
(use '[prowl.core :only [p]])

(defn method1 []
	(p :method1
		(Thread/sleep 100)))
(defn method2 []
	(p :method2
		(Thread/sleep 10)))

(defn logic []
	(p :logic :start (do (method1) (method2))))
	
(logic)	
```

Ouput log using `clojure.tools.logging`:
```
[WARN] 06-08 21:27:58,475 [user] - [prowl-profiler] nREPL-worker-0 logic-1370698078328153000 method1 : 145.903  msecs
[WARN] 06-08 21:27:58,487 [user] - [prowl-profiler] nREPL-worker-0 logic-1370698078328153000 method2 : 10.807  msecs
[WARN] 06-08 21:27:58,487 [user] - [prowl-profiler] nREPL-worker-0 logic-1370698078328153000 start : 159.588  msecs
```

Save the log in file `test.log`,download [parse.rb] to parse the log file:
```
ruby parse.rb  -f test.log
```

Output the statistics result:
```
Parsing log file test.log ...
Prowl profile results:
Labels:
  Label:logic count:1
    Method: method2                                            mean: 10.81      min: 10.81      max: 10.81      count: 1
    Method: method1                                            mean: 145.90     min: 145.90     max: 145.90     count: 1
    Method: start                                              mean: 159.59     min: 159.59     max: 159.59     count: 1

Methods:
  Method: method2                                            mean: 10.81      min: 10.81      max: 10.81      count: 1
  Method: method1                                            mean: 145.90     min: 145.90     max: 145.90     count: 1
  Method: start                                              mean: 159.59     min: 159.59     max: 159.59     count: 1
```

`p` macro accept label name,method name and expression:
```clojure
(p :label :method expr)
(p :method expr)
```
If you don't provide `label`,the default label is `no-label`.Once you profile expression with a `label`,the nested invocation of `(p :method expr)` will use the thread-bound label.

## License

Copyright © 2013 FIXME

Distributed under the Eclipse Public License, the same as Clojure.
