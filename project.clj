(defproject reminder-server "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "EPL-2.0 OR GPL-2.0-or-later WITH Classpath-exception-2.0"
            :url "https://www.eclipse.org/legal/epl-2.0/"}
  :dependencies [[org.clojure/clojure "1.10.0"]
                 [compojure "1.6.1"] ;; Routing
                 [clj-time "0.15.0"] ;; Time
                 [cheshire "5.8.1"] ;; JSON
                 [jarohen/chime "0.2.2"] ;; Scheduler
                 [clj-http "3.9.1"] ;; HTTP
                 [org.clojure/core.async "0.4.490"]
                 [ring/ring-defaults "0.3.2"]
                 [ring/ring-core "1.7.1"]
                 [ring/ring-json "0.4.0"]
                 [http-kit "2.3.0"]]
  :main ^:skip-aot reminder-server.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})
