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
