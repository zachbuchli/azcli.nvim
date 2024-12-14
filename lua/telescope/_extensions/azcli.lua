local azcli = require 'azcli'

return require('telescope').register_extension {
  exports = { azure_subscriptions = azcli.account_list },
}
