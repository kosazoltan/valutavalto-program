object RENDELOFORM: TRENDELOFORM
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'RENDELOFORM'
  ClientHeight = 412
  ClientWidth = 563
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
  object ALAPPANEL: TPanel
    Left = 0
    Top = 0
    Width = 561
    Height = 409
    BevelOuter = bvNone
    Color = clYellow
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 561
      Height = 409
      Align = alClient
      Brush.Color = clBtnFace
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 104
      Top = 24
      Width = 342
      Height = 42
      Caption = 'VALUTA FOGLAL'#193'SA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -35
      Font.Name = 'Stencil'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 112
      Top = 90
      Width = 218
      Height = 24
      Caption = 'Megrendelt valuta neme:'
      Transparent = True
    end
    object Label3: TLabel
      Left = 40
      Top = 128
      Width = 288
      Height = 24
      Caption = 'A megrendelt valuta mennyis'#233'ge:'
      Transparent = True
    end
    object Label4: TLabel
      Left = 48
      Top = 168
      Width = 183
      Height = 24
      Caption = 'Kialkudott '#225'rfolyam:'
      Transparent = True
    end
    object Label5: TLabel
      Left = 88
      Top = 208
      Width = 244
      Height = 24
      Caption = 'A megrendel'#233's forint '#233'rt'#233'ke:'
      Transparent = True
    end
    object Label6: TLabel
      Left = 152
      Top = 254
      Width = 181
      Height = 24
      Caption = 'Az '#252'gylet hat'#225'rideje:'
      Transparent = True
    end
    object Label7: TLabel
      Left = 72
      Top = 296
      Width = 263
      Height = 24
      Caption = #193'tvett fogad'#243' '#246'sszege '#233's neme:'
      Transparent = True
    end
    object Shape1: TShape
      Left = 98
      Top = 348
      Width = 364
      Height = 34
      Pen.Width = 2
      Shape = stRoundRect
    end
    object DNEMCOMBO: TComboBox
      Left = 336
      Top = 88
      Width = 73
      Height = 32
      DropDownCount = 12
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = []
      ItemHeight = 24
      ParentFont = False
      TabOrder = 0
      OnChange = DNEMCOMBOChange
    end
    object BJEGYEDIT: TEdit
      Left = 336
      Top = 126
      Width = 113
      Height = 30
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnEnter = BJEGYEDITEnter
      OnExit = BJEGYEDITExit
      OnKeyDown = BJEGYEDITKeyDown
    end
    object RDNEMPANEL: TPanel
      Left = 448
      Top = 120
      Width = 49
      Height = 41
      BevelOuter = bvNone
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object ARFOLYAMEDIT: TEdit
      Left = 240
      Top = 168
      Width = 121
      Height = 30
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      MaxLength = 5
      ParentFont = False
      TabOrder = 3
      OnEnter = ARFOLYAMEDITEnter
      OnExit = ARFOLYAMEDITExit
      OnKeyDown = ARFOLYAMEDITKeyDown
    end
    object FDNEMCOMBO: TComboBox
      Left = 448
      Top = 293
      Width = 73
      Height = 32
      DropDownCount = 3
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = []
      ItemHeight = 24
      ParentFont = False
      TabOrder = 4
      OnChange = FDNEMCOMBOChange
      OnEnter = FDNEMCOMBOEnter
    end
    object FOGLALOEDIT: TEdit
      Left = 336
      Top = 295
      Width = 113
      Height = 30
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnEnter = FOGLALOEDITEnter
      OnExit = FOGLALOEDITExit
      OnKeyDown = FOGLALOEDITKeyDown
    end
    object RENDFORINTPANEL: TPanel
      Left = 336
      Top = 210
      Width = 161
      Height = 25
      BevelOuter = bvNone
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
    end
    object HIDOEDIT: TEdit
      Left = 336
      Top = 250
      Width = 121
      Height = 32
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnEnter = HIDOEDITEnter
      OnExit = HIDOEDITExit
      OnKeyDown = HIDOEDITKeyDown
    end
    object ARANYPANEL: TPanel
      Left = 336
      Top = 166
      Width = 159
      Height = 33
      BevelOuter = bvNone
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
    end
    object RENDBENGOMB: TBitBtn
      Left = 104
      Top = 352
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'RENDEL'#201'S RENDBEN'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
      OnClick = RENDBENGOMBClick
    end
    object MEGSEMGOMB: TBitBtn
      Left = 288
      Top = 352
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 10
      OnClick = MEGSEMGOMBClick
    end
  end
  object FUGGONY: TPanel
    Left = -1587
    Top = 80
    Width = 545
    Height = 265
    BevelOuter = bvNone
    TabOrder = 1
    object Label8: TLabel
      Left = 56
      Top = 72
      Width = 442
      Height = 23
      Caption = 'MILYEN TRANZAKCI'#211'HOZ K'#201'RI A FOGLAL'#211'T ?'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Shape3: TShape
      Left = 130
      Top = 152
      Width = 295
      Height = 41
      Shape = stRoundRect
    end
    object VETELGOMB: TBitBtn
      Left = 136
      Top = 160
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'V'#201'TELHEZ'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = VETELGOMBClick
    end
    object ELADASGOMB: TBitBtn
      Left = 280
      Top = 160
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'ELAD'#193'SHOZ'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = ELADASGOMBClick
    end
  end
  object FQUERY: TIBQuery
    Database = FDBASE
    Transaction = FTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 24
  end
  object FDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = FTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 24
  end
  object FTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = FDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 24
  end
end
