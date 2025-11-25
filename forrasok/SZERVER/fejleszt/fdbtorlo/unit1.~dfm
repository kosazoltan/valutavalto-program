object Form1: TForm1
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 348
  ClientWidth = 496
  Color = clTeal
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label7: TLabel
    Left = 64
    Top = 16
    Width = 378
    Height = 29
    Caption = '2022 DECEMBERI ADATB'#193'ZIS RITKIT'#193'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -24
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object KILEPGOMB: TBitBtn
    Left = 256
    Top = 312
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'
    TabOrder = 0
    OnClick = KILEPGOMBClick
  end
  object STARTGOMB: TBitBtn
    Left = 112
    Top = 312
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = 'START'
    TabOrder = 1
    OnClick = STARTGOMBClick
  end
  object infopanel: TPanel
    Left = 0
    Top = 48
    Width = 489
    Height = 257
    Color = clMoneyGreen
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Calibri'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    object Label1: TLabel
      Left = 64
      Top = 72
      Width = 24
      Height = 23
      Caption = #201'V:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 152
      Top = 72
      Width = 65
      Height = 23
      Caption = 'H'#211'NAP:'
    end
    object Label3: TLabel
      Left = 288
      Top = 72
      Width = 59
      Height = 23
      Caption = 'FAROK:'
    end
    object Label4: TLabel
      Left = 48
      Top = 128
      Width = 186
      Height = 23
      Caption = 'T'#214'RLEND'#336' ADATB'#193'ZIS:'
    end
    object Label5: TLabel
      Left = 160
      Top = 24
      Width = 77
      Height = 23
      Caption = 'P'#201'NZT'#193'R:'
    end
    object Label6: TLabel
      Left = 48
      Top = 192
      Width = 81
      Height = 23
      Caption = 'PARANCS:'
    end
    object EVPANEL: TPanel
      Left = 96
      Top = 64
      Width = 41
      Height = 41
      BevelOuter = bvNone
      Caption = ' '
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object HOPANEL: TPanel
      Left = 224
      Top = 64
      Width = 41
      Height = 41
      BevelOuter = bvNone
      Caption = ' '
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object FAROKPANEL: TPanel
      Left = 352
      Top = 64
      Width = 65
      Height = 41
      BevelOuter = bvNone
      Caption = ' '
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object PENZTARPANEL: TPanel
      Left = 240
      Top = 16
      Width = 41
      Height = 41
      BevelOuter = bvNone
      Caption = ' '
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object FILEPANEL: TPanel
      Left = 240
      Top = 120
      Width = 185
      Height = 41
      BevelOuter = bvNone
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
    object PARANCSPANEL: TPanel
      Left = 136
      Top = 184
      Width = 337
      Height = 41
      BevelOuter = bvNone
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 56
  end
  object VDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
    Top = 56
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 248
    Top = 56
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 136
    Top = 56
  end
end
