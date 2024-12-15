local azcli = require 'azcli'

return require('telescope').register_extension {
  exports = { subscriptions = azcli.subscriptions, weblogs = azcli.webapp_logs },
}
