(in-package :hhub)
;;; GOVT OF INDIA DATA API
(defvar *HHUBAPI.GOV.IN.KEY* "579b464db66ec23bdd0000018e71c67835264f884d15916532e43a9b")
(defvar *HHUBGETPINCODEURLEXTERNAL* "https://api.data.gov.in/resource/5c2f62fe-5afa-4119-a499-fec9d604d5bd")


;; SMTP SETTINGS
(defvar *HHUBSMTPSERVER* "email-smtp.us-east-1.amazonaws.com")
(defvar *HHUBSMTPSENDER* "no-reply@highrisehub.com")
(defvar *HHUBSMTPTESTSENDER* "testsender@highrisehub.com")
(defvar *HHUBSMTPUSERNAME* "AKIA4UY2GODQGVLRCQUM")
(defvar *HHUBSMTPPASSWORD* "BOtGyU5ZpMNUiswDtganoDh4BzMP/0vSK8x3rXBmgSFa")


;; GOOGLE RECAPTCHA SERVICE
(defvar *HHUBRECAPTCHAURL* "https://www.google.com/recaptcha/api/siteverify")
(defvar *HHUBRECAPTCHAV2KEY* "6LeiXSQUAAAAAO-qh28CcnBFva6cQ68PCfxiMC0V") 
(defvar *HHUBRECAPTCHAV2SECRET*    "6LeiXSQUAAAAAFDP0jgtajXXvrOplfkMR9rWnFdO"   )


;; AWS SNS SETTINGS
(defvar *HHUBAWSSNSENTITYID* "1101737130000048961")
(defvar *HHUBAWSSNSSENDERID* "HIGHUB")
(defvar *HHUBAWSSNSOTPTEMPLATEID* "1107163272335247043")
(defvar *HHUBAWSSNSOTPTEMPLATETEXT* "OTP for Transaction is ~A. Valid for next 5 mins and can be used only once. Do not share OTP with anyone for security reasons. -HighriseHub")

;; iThink Logistics keys
(defvar *HHUBLOGISTICSKEY* "e293efaca02bd944bb53606c2ec6d66d")
(defvar *HHUBLOGISTICSSECRET* "85b9452cc683e05d1f9e1dbd37206719")
(defvar *HHUBLOGISTICSRATECHECKURL_STAGING* "https://pre-alpha.ithinklogistics.com/api_v3/rate/check.json")
(defvar *HHUBLOGISTICSRATECHECKURL_PROD* "https://manage.ithinklogistics.com/api_v3/rate/check.json")
(defvar *HHUBLOGISTICSADDORDERURL_STAGING* "https://pre-alpha.ithinklogistics.com/api_v3/order/add.json")
(defvar *HHUBLOGISTICSADDORDERURL_PROD* "https://manage.ithinklogistics.com/api_v3/order/add.json")
