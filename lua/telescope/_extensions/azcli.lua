local azcli = require 'azcli'

return require('telescope').register_extension {
  exports = { subscriptions = azcli.subscriptions, webapp_logs = azcli.webapp_logs },
}
