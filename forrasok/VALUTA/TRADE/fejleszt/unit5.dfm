object GETPENZTAROS: TGETPENZTAROS
  Left = 217
  Top = 114
  BorderStyle = bsNone
  Caption = 'GETPENZTAROS'
  ClientHeight = 281
  ClientWidth = 519
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
  object LISTAPANEL: TPanel
    Left = 0
    Top = 0
    Width = 545
    Height = 281
    BevelOuter = bvNone
    Color = clMoneyGreen
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 545
      Height = 281
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label1: TLabel
      Left = 48
      Top = 24
      Width = 432
      Height = 36
      Caption = 'P'#201'NZT'#193'ROS AZONOS'#205'T'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -32
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 40
      Top = 120
      Width = 179
      Height = 20
      Caption = 'P'#201'NZT'#193'ROS NEVE:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 96
      Top = 184
      Width = 107
      Height = 20
      Caption = 'JELSZAVA:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object prosnevpanel: TPanel
      Left = 216
      Top = 112
      Width = 289
      Height = 33
      Caption = 'aAHGAHGAHGAHGAHGAH'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object BitBtn2: TBitBtn
      Left = 288
      Top = 240
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM AZONOS'#205'TOK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      OnClick = BitBtn2Click
      OnEnter = JELSZOOKEGOMBEnter
      OnExit = JELSZOOKEGOMBExit
      OnMouseMove = JELSZOOKEGOMBMouseMove
    end
    object JELSZOOKEGOMB: TBitBtn
      Left = 88
      Top = 240
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'AZONOSIT'#193'S RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = JELSZOOKEGOMBClick
      OnEnter = JELSZOOKEGOMBEnter
      OnExit = JELSZOOKEGOMBExit
      OnMouseMove = JELSZOOKEGOMBMouseMove
    end
    object jelszoedit: TEdit
      Left = 216
      Top = 176
      Width = 289
      Height = 32
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      MaxLength = 10
      ParentFont = False
      PasswordChar = '#'
      TabOrder = 2
      Text = 'JELSZOEDIT'
      OnKeyDown = jelszoeditKeyDown
    end
    object PROSRACS: TDBGrid
      Left = 16
      Top = 80
      Width = 489
      Height = 145
      Cursor = crHandPoint
      Color = 13697023
      DataSource = DataSource1
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clTeal
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = PROSRACSDblClick
      OnKeyDown = PROSRACSKeyDown
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'PENZTAROSSZAM'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Times New Roman'
          Font.Style = [fsBold, fsItalic]
          Title.Alignment = taCenter
          Title.Caption = 'K'#211'D'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clBlack
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 108
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'PENZTAROSNEV'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Times New Roman'
          Font.Style = [fsBold, fsItalic]
          Title.Alignment = taCenter
          Title.Caption = 'P'#201'NZT'#193'ROSN'#201'V'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clBlack
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 374
          Visible = True
        end>
    end
  end
  object PROSQUERY: TIBQuery
    Database = prosdbase
    Transaction = PROSTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM PENZTAROSOK')
    Left = 40
    Top = 184
  end
  object prosdbase: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = PROSTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 184
  end
  object PROSTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = prosdbase
    AutoStopAction = saNone
    Left = 120
    Top = 184
  end
  object DataSource1: TDataSource
    DataSet = PROSQUERY
    Left = 160
    Top = 184
  end
end
