object Form1: TForm1
  Left = 192
  Top = 124
  Width = 870
  Height = 640
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object BitBtn1: TBitBtn
    Left = 584
    Top = 96
    Width = 75
    Height = 25
    Caption = 'KIL'#201'P'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object startgomb: TBitBtn
    Left = 456
    Top = 96
    Width = 75
    Height = 25
    Caption = 'LOGIR'#193'S'
    TabOrder = 1
    OnClick = startgombClick
  end
  object MESSEDIT: TEdit
    Left = 24
    Top = 96
    Width = 401
    Height = 21
    TabOrder = 2
    Text = 'MESSEDIT'
    OnEnter = MESSEDITEnter
    OnExit = MESSEDITExit
    OnKeyDown = MESSEDITKeyDown
  end
end
