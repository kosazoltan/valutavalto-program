object LIMITALLITOFORM: TLIMITALLITOFORM
  Left = 192
  Top = 123
  AlphaBlend = True
  AlphaBlendValue = 220
  BorderStyle = bsNone
  Caption = 'LIMITALLITOFORM'
  ClientHeight = 379
  ClientWidth = 546
  Color = clRed
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 529
    Height = 361
    Color = clInactiveCaptionText
    TabOrder = 0
    object Shape1: TShape
      Left = 336
      Top = 112
      Width = 121
      Height = 49
    end
    object Shape2: TShape
      Left = 336
      Top = 176
      Width = 121
      Height = 49
    end
    object Shape3: TShape
      Left = 336
      Top = 240
      Width = 121
      Height = 49
      Shape = stRoundRect
    end
    object Label1: TLabel
      Left = 64
      Top = 128
      Width = 255
      Height = 23
      Caption = 'ALS'#211' KEDVEZM'#201'NYHAT'#193'R'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 24
      Top = 192
      Width = 298
      Height = 23
      Caption = 'K'#214'Z'#201'PS'#336' KEDVEZM'#201'NYHAT'#193'R'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 48
      Top = 248
      Width = 269
      Height = 23
      Caption = 'FELS'#214' KEDVEZM'#201'NYHAT'#193'R'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 464
      Top = 248
      Width = 22
      Height = 27
      Caption = 'Ft'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 464
      Top = 192
      Width = 22
      Height = 27
      Caption = 'Ft'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label6: TLabel
      Left = 464
      Top = 128
      Width = 22
      Height = 27
      Caption = 'Ft'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label7: TLabel
      Left = 24
      Top = 16
      Width = 489
      Height = 31
      Caption = 'KEDVEZM'#201'NYHAT'#193'ROK BE'#193'LL'#205'T'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label8: TLabel
      Left = 240
      Top = 68
      Width = 105
      Height = 27
      Caption = 'CSOPORT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object K3EDIT: TEdit
      Left = 344
      Top = 248
      Width = 105
      Height = 35
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      Text = '1000000'
      OnChange = K1EDITChange
      OnEnter = K1EDITEnter
      OnExit = K1EDITExit
      OnKeyDown = K3EDITKeyDown
    end
    object K1EDIT: TEdit
      Left = 344
      Top = 120
      Width = 105
      Height = 35
      BevelInner = bvNone
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      Text = 'K1EDIT'
      OnChange = K1EDITChange
      OnEnter = K1EDITEnter
      OnExit = K1EDITExit
      OnKeyDown = K1EDITKeyDown
    end
    object K2EDIT: TEdit
      Left = 344
      Top = 184
      Width = 105
      Height = 35
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      Text = 'K2EDIT'
      OnChange = K1EDITChange
      OnEnter = K1EDITEnter
      OnExit = K1EDITExit
      OnKeyDown = K2EDITKeyDown
    end
    object CSOPORTPANEL: TPanel
      Left = 192
      Top = 58
      Width = 41
      Height = 41
      BevelOuter = bvNone
      Caption = '34.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object KEDVOKEGOMB: TBitBtn
      Left = 48
      Top = 304
      Width = 209
      Height = 25
      Cursor = crHandPoint
      Caption = 'KEDVEZM'#201'NYHAT'#193'ROK RENDBEN'
      TabOrder = 4
      OnClick = KEDVOKEGOMBClick
    end
    object MEGSEMGOMB: TBitBtn
      Left = 280
      Top = 304
      Width = 209
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM M'#211'DOS'#205'TOM'
      TabOrder = 5
      OnClick = MEGSEMGOMBClick
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTimer
    Left = 16
    Top = 72
  end
end
