-- the names of the concommands used to enable/disable extensions
-- (with a trailing space so we can concatenate extension names straight on)
local CONCOMMAND_NAMES = {
  [false] = "wire_expression2_extension_disable ",
  [true] = "wire_expression2_extension_enable "
}

-- the same parameters as DermaDefault, but with italic=true
surface.CreateFont("DermaDefaultItalic", {
  font = system.IsLinux() and "DejaVu Sans" or "Tahoma",
  size = system.IsLinux() and 14 or 13,
  italic = true,
})

local function ShowExtensionMenu()
  local frame = vgui.Create("DFrame")
  frame:SetTitle("Expression2 extensions")
  frame:SetSize(400, 400)
  frame:SetMinWidth(400)
  frame:SetSizable(true)
  frame:MakePopup()

  local checkboxes_disabled
  if not LocalPlayer():IsSuperAdmin() then
    checkboxes_disabled = true
    local label = Label("You are not a super admin - you cannot change these settings, only view them.", frame)
    label:SetTextColor(Color(203, 153, 51))
    label:Dock(TOP)
  end

  local scroll = vgui.Create("DScrollPanel", frame)
  scroll:Dock(FILL)
  local list = vgui.Create("DListLayout", scroll)
  list:Dock(FILL)

  for _, name in pairs(E2Lib.GetExtensions()) do
    local item = vgui.Create("DListLayout", list)
    item:DockPadding(5, 5, 5, 5)
    item:SetPaintBackground(true)

    local checkbox = vgui.Create("DCheckBoxLabel", item)
    checkbox:SetText(name)
    checkbox:SetChecked(E2Lib.GetExtensionStatus(name))
    checkbox.Button:SetDisabled(checkboxes_disabled)
    checkbox:SizeToContents()
    checkbox:SetDark(true)
    function checkbox:OnChange(value)
      LocalPlayer():ConCommand(CONCOMMAND_NAMES[value] .. name)
    end

    if not checkboxes_disabled then
      function item:OnMouseReleased() checkbox:Toggle() end
    end

    local documentation = E2Lib.GetExtensionDocumentation(name)
    if documentation.Description then
      local description = Label(documentation.Description, item)
      description:DockMargin(40, 5, 5, 5)
      description:SetWrap(true)
      description:SetDark(true)
      description:SetAutoStretchVertical(true)
      description:SetFont("DermaDefaultItalic")
    end

    -- only show warnings to admins - because they're typically warnings about
    -- the ways players could exploit E2 extensions. (Yes, this is a bit
    -- paranoid, and security through obscurity is not security.)
    if LocalPlayer():IsSuperAdmin() and documentation.Warning then
      local warning = Label(documentation.Warning, item)
      warning:DockMargin(40, 5, 5, 5)
      warning:SetWrap(true)
      warning:SetTextColor(Color(153, 51, 0))
      warning:SetAutoStretchVertical(true)
      warning:SetFont("DermaDefaultBold")
    end
  end
end

concommand.Add("wire_expression2_extension_menu", ShowExtensionMenu)

local function ShowMenuDialog()
  local panel = vgui.Create("DListLayout")
  panel:SetWide(400)
  panel:SetPos(ScrW() * 3/4 - 200, 0)
  panel:DockPadding(10, 10, 10, 10)

  panel:SetPaintBackgroundEnabled(true)
  panel:SetPaintBorderEnabled(true)
  panel:SetMouseInputEnabled(true)
  panel:SetDrawBackground(true)

  local header = Label("E2 extensions", panel)
  header:SetDark(true)
  header:SetFont("DermaLarge")
  header:Dock(TOP)

  local label = Label("Wiremod includes Expression2, a powerful programmable microchip. It has an extension system, " ..
          "which allows it to do things like make HTTP requests and run console commands. As a super " ..
          "admin, you should take a moment to look over the extensions, as some of them affect the " ..
          "security of your server.", panel)
  label:Dock(TOP)
  label:SetWrap(true)
  label:SetDark(true)
  label:SetAutoStretchVertical(true)

  local yes_button = vgui.Create("DButton")
  yes_button:SetText("Show me the extensions")
  function yes_button:GetToggle() return true end -- makes it draw blue
  function yes_button.DoClick()
    ShowExtensionMenu()
    panel:Remove()
  end

  local no_button = vgui.Create("DButton")
  no_button:SetText("Not now")
  function no_button.DoClick()
    panel:Remove()
    LocalPlayer():PrintMessage(HUD_PRINTTALK, "You can reopen the E2 extension menu in future with the command wire_expression2_extension_menu.")
  end

  local button_area = vgui.Create("DPanel", panel)
  button_area:SetHeight(yes_button:GetTall())
  button_area:Dock(TOP)
  button_area:DockMargin(0, 10, 0, 0)
  yes_button:SetParent(button_area)
  no_button:SetParent(button_area)

  panel:InvalidateLayout(true)

  local dividing_point = button_area:GetWide() * 2/3
  yes_button:SetPos(0, 0)
  yes_button:SetWide(dividing_point - 2)
  no_button:SetPos(dividing_point + 2, 0)
  no_button:SetWide(button_area:GetWide() - dividing_point - 2)
end

hook.Add("InitPostEntity", "wire_expression2_extension_menu", function()
  if LocalPlayer():IsSuperAdmin() then
    ShowMenuDialog() -- TODO cookie
  end
end)
