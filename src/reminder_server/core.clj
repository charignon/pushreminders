(ns reminder-server.core
  (:gen-class)
  (:require [compojure.core :refer :all]
            [compojure.route :as route]
            [ring.middleware.json :refer :all]
            [ring.util.response :refer :all]
            [chime :refer [chime-ch chime-at]]
            [clj-http.client :as client]
            [clj-time.core :as t]
            [clj-time.format :as f]
            [cheshire.core :refer [parse-string]]
            [org.httpkit.server :refer [run-server]]))

;; West Coast Timezone
(def am-tz (t/time-zone-for-id "America/Los_Angeles"))

;; Parser for Org mode dates
(def org-parser (f/formatter am-tz "yyyy-MM-dd E HH:mm" "yyyy-MM-dd E"))

;; Endpoint to post messages to pushover
(def pushover-endpoint "https://api.pushover.net/1/messages.json")

;; Reminder file
(def reminders-file "/home/laurent/Documents/reminders.json")

(defn send-fn []
  "Return a function that accepts a message and sends it to pushover"
  (let [tok (System/getenv "pushover_tok")
        usr (System/getenv "pushover_key")]
    (if (and tok usr)
      (fn [msg]
        (client/post pushover-endpoint {:form-params {:token tok :user usr :message msg}})
        (println "Sent a message!"))
      (throw "Please check your configuration, missing env variable pushover_tok or pushover_key"))))

(defn cancel-timers [timers]
  "Eliminate all the pending timers"
  (doseq [f timers] (f)))

(defn reminder-schedule [r]
  "Return the schedule for reminder r or throws is no date"
  (if (:date r)
    (list (f/parse org-parser (:date r)))
    (throw "Not a valid reminder")))

(defn parse-reminders [filename]
  "Parse filename, return reminders"
  (-> (slurp filename) (parse-string true)))

(defn reminder-msg [r]
  "Given a reminder r returns its message"
  (or (:message r) (:title r)))

(defn do-replace-reminders [{:keys [timers reminders-file send-fn] :as state}]
  "Replace all current timers with fresh ones from the reminder file"
  (cancel-timers timers)
  (let [new-timers (doseq [r (parse-reminders reminders-file)]
                     (chime-at (reminder-schedule r)
                               (fn [_] (send-fn (reminder-msg r)))))]
    (assoc state :timers new-timers)))

;; Web stuff
(def app-state (atom {:port 3000 :timers [] :reminders-file reminders-file :send-fn (send-fn)}))

(defn replace-reminders []
  "Replace all the reminders"
  (let [old-app-state @app-state
        new-app-state (do-replace-reminders old-app-state)]
    (println "Reloading reminders")
    (when (not= old-app-state new-app-state)
      (println (format "State changed! new state: %s" new-app-state))
      (reset! app-state new-app-state))))

(defroutes app
  (GET "/" request (fn [_]
                     (replace-reminders)
                     (response "OK")))
  (route/not-found "Not found"))

(defn -main
  [& args]
  (println "Started!")
  ((send-fn) "Started reminders server")
  (replace-reminders)
  (run-server
   (wrap-json-body app {:keywords? true})
   {:port (:port @app-state)}))
