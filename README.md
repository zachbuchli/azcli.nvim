# azcli.nvim

Neovim plugin that wraps the Azure CLI.


## Installation with Lazy.nvim

```lua
{
  'zachbuchli/azcli.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    local themes = require 'telescope.themes'
    local telescope = require 'telescope'

    telescope.load_extension 'azcli'

    vim.keymap.set('n', '<leader>as', function()
      telescope.extensions.azcli.subscriptions(themes.get_dropdown {})
    end, { desc = 'Opens picker for Azcli Subscriptions' })

    vim.keymap.set('n', '<leader>al', function()
      telescope.extensions.azcli.webapp_logs(themes.get_ivy {})
    end, { desc = 'Opens picker for Azure Web app logs' })
  end,
}
```
