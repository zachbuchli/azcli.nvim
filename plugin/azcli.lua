vim.api.nvim_create_user_command('Az', function(opts)
  require('azcli').show(opts.fargs, { color_output = true })
end, {
  nargs = '+',
  desc = ':Az <cmds> displays results of azure cli in floating window.',
})
