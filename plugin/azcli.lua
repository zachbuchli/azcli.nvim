vim.api.nvim_create_user_command('Az', function(opts)
  require('azcli').show()
end, {
  desc = ':Az displays results of azure cli in floating window.',
})
