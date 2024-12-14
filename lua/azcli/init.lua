local conf = require('telescope.config').values
local pickers = require 'telescope.pickers'
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local finders = require 'telescope.finders'
local previewers = require 'telescope.previewers'
local utils = require 'telescope.previewers.utils'
--local plenary = require 'plenary'

local M = {}

-- setup is often used to setup defaults/config for a plugin.
M.setup = function(opts)
  opts = opts or {}
end

---Open a floating window used to display az cli
---@param cmd? string[]
---@param opts? {win?:integer}
function M.show(cmd, opts)
  opts = opts or {}
  cmd = cmd or { 'account', 'show' }
  print(vim.inspect(cmd))

  -- Create an immutable scratch buffer that is wiped once hidden
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  -- Create a floating window using the scratch buffer positioned in the middle
  local height = math.ceil(vim.o.lines * 0.8) -- 80% of screen height
  local width = math.ceil(vim.o.columns * 0.8) -- 80% of screen width
  local win = vim.api.nvim_open_win(buf, true, {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    row = math.ceil((vim.o.lines - height) / 2),
    col = math.ceil((vim.o.columns - width) / 2),
    border = 'single',
  })

  -- set buffer local keymap for easy exits
  vim.keymap.set('n', 'q', ':q<CR>', { buffer = buf, silent = true })

  -- Change to the window that is floating to ensure termopen uses correct size
  vim.api.nvim_set_current_win(win)

  vim.fn.termopen { 'az', unpack(cmd) }
end

---Call azcli with cmd and return results as table.
---@return table|nil, string?
---@param cmd string[]
M.call = function(cmd)
  if vim.list_contains(cmd, '-o') or vim.list_contains(cmd, '--output') then
    return nil, 'Only json output is supported.'
  end
  local full_cmd = { 'az', unpack(cmd) }
  local results = vim.system(full_cmd, { text = true }):wait()
  if results.code ~= 0 then
    return nil, results.stderr
  end
  local response = vim.json.decode(results.stdout)
  return response
end

-- telescope extension for picking active azcli account
M.account_list = function(opts)
  pickers
    .new(opts, {
      finder = finders.new_dynamic {
        fn = function()
          local results = M.call { 'account', 'list' }
          return results
        end,

        entry_maker = function(entry)
          if entry then
            return {
              value = entry,
              display = entry.name,
              ordinal = entry.name,
            }
          end
        end,
      },

      sorter = conf.generic_sorter(opts),

      previewer = previewers.new_buffer_previewer {
        title = 'Subscription Info',
        define_preview = function(self, entry)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, vim.insect(entry))
          utils.highlighter(self.state.bufnr, 'json')
        end,
      },

      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local cmd = { 'account', 'set', '--subscription', selection.value.name }
          M.call(cmd)
        end)
        return true
      end,
    })
    :find()
end
return M
