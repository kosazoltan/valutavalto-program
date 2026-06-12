object Form2: TForm2
  Left = 717
  Top = 210
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 419
  ClientWidth = 427
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
  object CIMLETEZOPANEL: TPanel
    Left = 0
    Top = 0
    Width = 425
    Height = 417
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 425
      Height = 417
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 388
      Height = 36
      Caption = 'HRK H'#193'ZIP'#201'NZT'#193'R CIMLETEZ'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 56
      Top = 56
      Width = 64
      Height = 29
      Caption = '1.000'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 72
      Top = 88
      Width = 43
      Height = 29
      Caption = '500'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 72
      Top = 128
      Width = 43
      Height = 29
      Caption = '200'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 72
      Top = 160
      Width = 43
      Height = 29
      Caption = '100'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label6: TLabel
      Left = 88
      Top = 192
      Width = 29
      Height = 29
      Caption = '50'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label7: TLabel
      Left = 88
      Top = 224
      Width = 29
      Height = 29
      Caption = '20'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label8: TLabel
      Left = 88
      Top = 256
      Width = 29
      Height = 29
      Caption = '10'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label9: TLabel
      Left = 80
      Top = 304
      Width = 108
      Height = 23
      Caption = 'Z'#193'R'#211'K'#201'SZLET'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label10: TLabel
      Left = 248
      Top = 304
      Width = 103
      Height = 23
      Caption = 'CIMLETEZETT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object E1: TEdit
      Tag = 1
      Left = 144
      Top = 60
      Width = 73
      Height = 28
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      MaxLength = 4
      ParentFont = False
      TabOrder = 0
      Text = ' '
      OnEnter = E1Enter
      OnExit = E1Exit
      OnKeyDown = E1KeyDown
    end
    object E2: TEdit
      Tag = 2
      Left = 144
      Top = 94
      Width = 73
      Height = 28
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      MaxLength = 4
      ParentFont = False
      TabOrder = 1
      Text = ' '
      OnEnter = E1Enter
      OnExit = E1Exit
      OnKeyDown = E1KeyDown
    end
    object E3: TEdit
      Tag = 3
      Left = 144
      Top = 128
      Width = 73
      Height = 28
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      MaxLength = 4
      ParentFont = False
      TabOrder = 2
      Text = ' '
      OnEnter = E1Enter
      OnExit = E1Exit
      OnKeyDown = E1KeyDown
    end
    object E4: TEdit
      Tag = 4
      Left = 144
      Top = 160
      Width = 73
      Height = 28
      BorderStyle = bsNone
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      MaxLength = 4
      ParentFont = False
      TabOrder = 3
      Text = ' '
      OnEnter = E1Enter
      OnExit = E1Exit
      OnKeyDown = E1KeyDown
    end
    object E5: TEdit
      Tag = 5
      Left = 144
      Top = 192
      Width = 73
      Height = 28
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      MaxLength = 4
      ParentFont = False
      TabOrder = 4
      Text = ' '
      OnEnter = E1Enter
      OnExit = E1Exit
      OnKeyDown = E1KeyDown
    end
    object E6: TEdit
      Tag = 6
      Left = 144
      Top = 224
      Width = 73
      Height = 28
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      MaxLength = 4
      ParentFont = False
      TabOrder = 5
      Text = ' '
      OnEnter = E1Enter
      OnExit = E1Exit
      OnKeyDown = E1KeyDown
    end
    object E7: TEdit
      Tag = 7
      Left = 144
      Top = 256
      Width = 73
      Height = 28
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      MaxLength = 4
      ParentFont = False
      TabOrder = 6
      Text = ' '
      OnEnter = E1Enter
      OnExit = E1Exit
      OnKeyDown = E1KeyDown
    end
    object P1: TPanel
      Left = 220
      Top = 62
      Width = 133
      Height = 30
      BevelOuter = bvNone
      Caption = 'P1'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
    end
    object P2: TPanel
      Left = 220
      Top = 96
      Width = 133
      Height = 30
      BevelOuter = bvNone
      Caption = 'P2'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
    end
    object P3: TPanel
      Left = 220
      Top = 128
      Width = 133
      Height = 30
      BevelOuter = bvNone
      Caption = 'P3'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 9
    end
    object P4: TPanel
      Left = 220
      Top = 160
      Width = 133
      Height = 30
      BevelOuter = bvNone
      Caption = 'P4'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 10
    end
    object P5: TPanel
      Left = 220
      Top = 192
      Width = 133
      Height = 30
      BevelOuter = bvNone
      Caption = 'P5'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 11
    end
    object P6: TPanel
      Left = 220
      Top = 224
      Width = 133
      Height = 30
      BevelOuter = bvNone
      Caption = 'P6'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 12
    end
    object P7: TPanel
      Left = 220
      Top = 256
      Width = 133
      Height = 30
      BevelOuter = bvNone
      Caption = 'P7'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 13
    end
    object KESZLETPANEL: TPanel
      Left = 64
      Top = 328
      Width = 133
      Height = 33
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Stencil'
      Font.Style = []
      ParentFont = False
      TabOrder = 14
    end
    object CIMLETPANEL: TPanel
      Left = 224
      Top = 328
      Width = 133
      Height = 33
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Stencil'
      Font.Style = []
      ParentFont = False
      TabOrder = 15
    end
    object CIMOKEGOMB: TBitBtn
      Left = 24
      Top = 376
      Width = 177
      Height = 25
      Caption = 'CIMLETEK RENDBEN'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 16
      OnClick = CIMOKEGOMBClick
    end
    object CIMMEGSEMGOMB: TBitBtn
      Left = 224
      Top = 376
      Width = 177
      Height = 25
      Caption = 'VISSZA A MEN'#220'RE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 17
      OnClick = CIMMEGSEMGOMBClick
    end
  end
  object HRKQUERY: TIBQuery
    Database = HRKDBASE
    Transaction = HRKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 64
  end
  object HRKDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\hazihrk.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = HRKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 16
    Top = 104
  end
  object HRKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HRKDBASE
    AutoStopAction = saNone
    Left = 16
    Top = 144
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTimer
    Left = 16
    Top = 184
  end
end
