(ns prowl.core
  (:use [environ.core :only [env]])
  (:import [java.util HashMap])
  (:require [clojure.tools.logging :as log]))

(defonce ^{:private true :tag ThreadLocal} -thread-bound-profiler (ThreadLocal.))

(defonce ^{:dynamic true} *profile (env :prowl-profile "true"))

(defn -now []
  (System/nanoTime))

(defn -profiler [^String label]
  (if-let [^String s (.get -thread-bound-profiler)]
    (if (and label (not (.startsWith s (str label "-"))))
      (throw (IllegalStateException. (str "There is a profiler " s " bound to current thread already.")))
      [false s])
    (let [s (str (name (or label "no-label")) "-" (-now))]
      (.set -thread-bound-profiler s)
      [true s])))

(defn -invalidate []
  (.remove -thread-bound-profiler))

(defmacro p
  ([method expr]
     `(p nil ~method ~expr))
  ([label method expr]
     `(if *profile
        (let [[created# ts#] (-profiler ~label)
              start# (-now)]
          (try
            (let [ret# ~expr]
              (log/warn "[prowl-profiler]" ts# (name ~method) ":" (/ (double (- (-now) start#)) 1000000.0) " msecs")
              ret#)
            (finally
             (when created#
               (-invalidate)))))
        ~expr)))


