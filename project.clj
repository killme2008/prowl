(defproject prowl "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.4.0"]
                 [org.clojure/tools.logging "0.2.3"]]
  :profiles
  {:dev {:dependencies [[org.slf4j/slf4j-log4j12 "1.7.2"]
                        [log4j "1.2.16"]
                        [environ "0.3.0"]
                        [org.slf4j/slf4j-api "1.7.2"]]
         :resource-paths ["src/dev"]}})
