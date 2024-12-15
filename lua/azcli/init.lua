local conf = require('telescope.config').values
local pickers = require 'telescope.pickers'
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local finders = require 'telescope.finders'
local previewers = require 'telescope.previewers'
local themes = require 'telescope.themes'

local M = {}

-- setup is often used to setup defaults/config for a plugin.
M.setup = function(opts)
  opts = opts or {}
end

---Open a floating window used to display az cli
---@param cmd string[]
---@param opts? {win?:integer}
function M.show(cmd, opts)
  opts = opts or {}
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
    title = opts.title or 'Azure CLI',
    title_pos = 'center',
  })

  -- set buffer local keymap for easy exits
  vim.keymap.set('n', 'q', ':q<CR>', { buffer = buf, silent = true })

  -- Change to the window that is floating to ensure termopen uses correct size
  vim.api.nvim_set_current_win(win)

  vim.fn.termopen { 'az', unpack(cmd) }
  vim.cmd '$'
end

---Call azcli with cmd and return results as table.
---@param cmd string[]
---@return table|nil, string?
M.call = function(cmd)
  if vim.list_contains(cmd, '-o') or vim.list_contains(cmd, '--output') then
    return nil, 'Only json output is supported.'
  end
  local full_cmd = { 'az', unpack(cmd) }
  local results = vim.system(full_cmd, { text = true }):wait()
  if results.code ~= 0 then
    return nil, results.stderr
  end
  if results.stdout == '' then
    return {}
  end
  local response = vim.json.decode(results.stdout)
  return response
end

--print(vim.inspect(M.call { 'account', 'list' }))

-- telescope extension for picking active azcli set subscription
M.subscriptions = function(opts)
  local results = M.call { 'account', 'list' }
  local account = M.call { 'account', 'show' }
  account = account or {}
  local prompt_title = string.format('Set Subscription (Current = %s)', account.name or '')
  pickers
    .new(opts, {
      prompt_title = prompt_title,
      results_title = 'Azure Subscriptions',
      finder = finders.new_table {
        results = results,
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
        title = 'Subscription Details',
        define_preview = function(self, entry)
          local lines = {}
          for k, v in pairs(entry.value) do
            if type(v) ~= 'table' then
              local line = string.format('%s = %s', k, v)
              table.insert(lines, line)
            end
          end
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, lines)
        end,
      },

      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local cmd = { 'account', 'set', '--subscription', selection.value.name }
          local _, err = M.call(cmd)
          if err then
            vim.notify(err)
          else
            vim.notify(string.format('Azcli subscription set to %s', selection.value.name))
          end
        end)
        return true
      end,
    })
    :find()
end

-- telescope extension for picking which logs to view.
M.webapp_logs = function(opts)
  local results = M.call { 'webapp', 'list' }
  local account = M.call { 'account', 'show' }
  account = account or {}
  local prompt_title = string.format('Choose log to view (Sub = %s)', account.name or '')
  pickers
    .new(opts, {
      prompt_title = prompt_title,
      results_title = 'Azure Webapps',
      finder = finders.new_table {
        results = results,
        entry_maker = function(entry)
          if entry then
            return {
              value = entry,
              display = entry.name,
              ordinal = entry.name .. ' ' .. entry.resourceGroup .. ' ' .. entry.state,
            }
          end
        end,
      },

      sorter = conf.generic_sorter(opts),

      previewer = previewers.new_buffer_previewer {
        title = 'Web App Details',
        define_preview = function(self, entry)
          local lines = {
            string.format('name: %s', entry.value.name),
            string.format('resource group: %s', entry.value.resourceGroup),
            string.format('location: %s', entry.value.location),
            string.format('state: %s', entry.value.state),
          }
          for k, v in pairs(entry.value.tags) do
            local line = string.format('tag: %s = %s', k, v)
            table.insert(lines, line)
          end
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, lines)
        end,
      },

      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local name = selection.value.name
          local rg = selection.value.resourceGroup
          local cmd = { 'webapp', 'log', 'tail', '-g', rg, '-n', name }
          local title = string.format('%s log tail', name)
          M.show(cmd, { start_insert = true, title = title })
        end)
        return true
      end,
    })
    :find()
end

M.test_logs = function()
  M.webapp_logs(themes.get_ivy {})
end

M.test_subs = function()
  M.subscriptions(themes.get_ivy {})
end

return M
