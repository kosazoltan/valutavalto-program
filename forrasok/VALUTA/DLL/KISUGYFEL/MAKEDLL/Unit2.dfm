object Form2: TForm2
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 353
  ClientWidth = 590
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape2: TShape
    Left = 0
    Top = 0
    Width = 590
    Height = 353
    Align = alClient
    Pen.Color = clRed
    Pen.Width = 3
  end
  object Label6: TLabel
    Left = 40
    Top = 16
    Width = 523
    Height = 24
    Caption = '300.000 FORINT ALATTI KIS'#220'GYF'#201'L AZONOSIT'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object KUGYFELPANEL: TPanel
    Left = -1987
    Top = 80
    Width = 589
    Height = 233
    BevelOuter = bvNone
    Color = clYellow
    TabOrder = 0
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 589
      Height = 233
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label2: TLabel
      Left = 216
      Top = 16
      Width = 165
      Height = 22
      Caption = 'AZ '#220'GYF'#201'L NEVE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 208
      Top = 72
      Width = 175
      Height = 22
      Caption = 'SZ'#220'LET'#201'SI HELYE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 216
      Top = 128
      Width = 166
      Height = 22
      Caption = 'SZ'#220'LET'#201'SI IDEJE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object KUGYOKEGOMB: TBitBtn
      Left = 80
      Top = 192
      Width = 209
      Height = 25
      Cursor = crHandPoint
      Caption = 'ADATOK RENDBEN'
      TabOrder = 0
      OnClick = KUGYOKEGOMBClick
    end
    object KUGYMEGSEMGOMB: TBitBtn
      Left = 296
      Top = 192
      Width = 209
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM AZONOS'#205'TJA MAG'#193'T'
      TabOrder = 1
      OnClick = KUGYMEGSEMGOMBClick
    end
    object NEVEDIT: TEdit
      Tag = 1
      Left = 64
      Top = 40
      Width = 457
      Height = 27
      Cursor = crHandPoint
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      MaxLength = 40
      ParentFont = False
      TabOrder = 2
      Text = ' '
      OnEnter = NEVEDITEnter
      OnExit = NEVEDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object SZULHELYEDIT: TEdit
      Tag = 2
      Left = 64
      Top = 96
      Width = 457
      Height = 27
      Cursor = crHandPoint
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      MaxLength = 40
      ParentFont = False
      TabOrder = 3
      Text = ' '
      OnEnter = NEVEDITEnter
      OnExit = NEVEDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object SZULIDOEDIT: TEdit
      Tag = 3
      Left = 248
      Top = 152
      Width = 113
      Height = 27
      Cursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      MaxLength = 10
      ParentFont = False
      TabOrder = 4
      Text = ' '
      OnEnter = NEVEDITEnter
      OnExit = NEVEDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object LISTAGOMB: TBitBtn
      Left = 456
      Top = 8
      Width = 113
      Height = 25
      Cursor = crHandPoint
      Caption = 'R'#201'GI '#220'GYF'#201'L'
      TabOrder = 5
      OnClick = LISTAGOMBClick
    end
    object KERESOPANEL: TPanel
      Left = -1978
      Top = 56
      Width = 553
      Height = 230
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 6
      Visible = False
      object Label5: TLabel
        Left = 10
        Top = 10
        Width = 81
        Height = 18
        Caption = 'KERES'#201'S:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object KUGYRACS: TDBGrid
        Left = 0
        Top = 40
        Width = 553
        Height = 160
        Cursor = crHandPoint
        DataSource = KUGYSOURCE
        Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
        ReadOnly = True
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        OnCellClick = KUGYRACSCellClick
        OnDblClick = KUGYRACSDblClick
        OnKeyUp = KUGYRACSKeyUp
        Columns = <
          item
            Expanded = False
            FieldName = 'NEV'
            Title.Alignment = taCenter
            Title.Caption = #220'GYF'#201'L NEVE'
            Title.Color = 11599871
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'SZULETESIHELY'
            Title.Alignment = taCenter
            Title.Caption = 'SZ'#220'LET'#201'SI HELY'
            Title.Color = 11599871
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'SZULETESIIDO'
            Title.Alignment = taCenter
            Title.Caption = 'SZ'#220'L-I ID'#336
            Title.Color = 11599871
            Visible = True
          end>
      end
      object KERESOEDIT: TEdit
        Left = 104
        Top = 8
        Width = 177
        Height = 25
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ParentFont = False
        ReadOnly = True
        TabOrder = 1
      end
      object NOCHOOSEGOMB: TBitBtn
        Left = 408
        Top = 8
        Width = 137
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM V'#193'LASZTOK'
        TabOrder = 2
        OnClick = NOCHOOSEGOMBClick
      end
    end
  end
  object UZENOPANEL: TPanel
    Left = 16
    Top = 56
    Width = 553
    Height = 25
    BevelOuter = bvNone
    Caption = 'NEM KELL AZONOSITANI'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -21
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
    Visible = False
  end
  object INDOKPANEL: TPanel
    Left = -1999
    Top = 56
    Width = 377
    Height = 217
    BevelOuter = bvNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Calibri'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
    Visible = False
    object Shape3: TShape
      Left = 0
      Top = 0
      Width = 377
      Height = 217
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 349
      Height = 23
      Caption = 'AZ '#220'GYF'#201'L TELJES AZONOSIT'#193'SA SZ'#220'KS'#201'GES'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label7: TLabel
      Left = 160
      Top = 48
      Width = 59
      Height = 19
      Caption = 'INDOKA:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label8: TLabel
      Left = 56
      Top = 72
      Width = 169
      Height = 19
      Caption = 'UTOLS'#211' V'#193'LT'#193'S D'#193'TUMA:'
      Transparent = True
    end
    object Label9: TLabel
      Left = 120
      Top = 96
      Width = 106
      Height = 19
      Caption = 'UTOLS'#211' V'#193'LT'#193'S:'
      Transparent = True
    end
    object Label10: TLabel
      Left = 112
      Top = 120
      Width = 115
      Height = 19
      Caption = 'MOSTANI V'#193'LT'#193'S:'
      Transparent = True
    end
    object Label11: TLabel
      Left = 22
      Top = 144
      Width = 205
      Height = 19
      Caption = #214'SSZES V'#193'LT'#193'S 1 H'#201'TEN BEL'#220'L:'
      Transparent = True
    end
    object ZDATUMPANEL: TPanel
      Left = 232
      Top = 72
      Width = 81
      Height = 22
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object UTFTPANEL: TPanel
      Left = 232
      Top = 96
      Width = 105
      Height = 22
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object AKTFTPANEL: TPanel
      Left = 232
      Top = 120
      Width = 105
      Height = 22
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object OSSZFTPANEL: TPanel
      Left = 232
      Top = 144
      Width = 105
      Height = 22
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object TOVABBGOMB: TButton
      Left = 128
      Top = 176
      Width = 113
      Height = 25
      Caption = 'TOV'#193'BB'
      TabOrder = 4
      OnClick = TOVABBGOMBClick
    end
  end
  object LOCALQUERY: TIBQuery
    Database = LOCALDBASE
    Transaction = LOCALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 24
    Top = 184
  end
  object LOCALDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = LOCALTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 184
  end
  object LOCALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = LOCALDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 184
  end
  object KUGYSOURCE: TDataSource
    DataSet = LOCALQUERY
    Left = 16
    Top = 8
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 216
  end
  object REMOTEDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = REMOTETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 216
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 216
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 344
    Top = 8
  end
end
