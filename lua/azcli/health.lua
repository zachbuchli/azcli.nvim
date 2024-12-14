local M = {}

M.check = function()
  vim.health.start 'azcli'

  if vim.fn.executable 'az' == 0 then
    vim.health.error 'az not found on path'
    return
  end

  -- Indicate that we found curl, which is good!
  vim.health.ok 'az found on path'

  -- Pull the version information about curl
  local results = vim.system({ 'az', 'version', '--query', '"azure-cli"' }, { text = true }):wait()

  -- If we get a non-zero exit code, something went wrong
  if results.code ~= 0 then
    vim.health.error("failed to retrieve az's version", results.stderr)
    return
  end

  -- NOTE: While `vim.version.parse` should return nil on invalid input,
  --       having something really invalid like "abc" will cause it to
  --       throw an error on neovim 0.10.0! Make sure you're using 0.10.2!
  local v = vim.version.parse(results.stdout or '')
  if not v then
    vim.health.error('invalid az version output', results.stdout)
    return
  end

  -- Require curl 8.x.x
  if v.major ~= 2 then
    vim.health.error('az must be 2.x.x, but got ' .. tostring(v))
    return
  end

  -- Curl is a good version, so lastly we'll test the weather site
  vim.health.ok('az ' .. tostring(v) .. ' is an acceptable version')
end

return M
