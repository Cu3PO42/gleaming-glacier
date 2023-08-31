return {
  "mfussenegger/nvim-dap",
  dependencies = {
    --{
      --"Joakker/lua-json5",
      --build = "./install.sh"
    --},
  },
  config = function ()
    local dap = require("dap.ext.vscode")
    --dap.json_decode = require('json5').parse
  end,
}

