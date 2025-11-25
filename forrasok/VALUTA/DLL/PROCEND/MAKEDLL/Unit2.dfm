object PROCENDFORM: TPROCENDFORM
  Left = 360
  Top = 290
  BorderStyle = bsNone
  ClientHeight = 56
  ClientWidth = 298
  Color = clYellow
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object HIDEEDIT: TEdit
    Left = 168
    Top = 16
    Width = 41
    Height = 21
    TabOrder = 1
    Text = 'HIDEEDIT'
    OnEnter = HIDEEDITEnter
    OnExit = HIDEEDITExit
    OnKeyPress = HIDEEDITKeyPress
  end
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 281
    Height = 41
    Cursor = crHandPoint
    BevelOuter = bvNone
    Caption = 'NYOMJON EGY SPACE-T !'
    Color = clRed
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    OnClick = Panel1Click
  end
end
