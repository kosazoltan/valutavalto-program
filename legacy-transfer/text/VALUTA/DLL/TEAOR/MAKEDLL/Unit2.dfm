object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 347
  ClientWidth = 507
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
  object RACSPANEL: TPanel
    Left = 0
    Top = 0
    Width = 505
    Height = 345
    BevelOuter = bvNone
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 505
      Height = 345
      Align = alClient
      Brush.Color = clBtnFace
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label1: TLabel
      Left = 32
      Top = 16
      Width = 450
      Height = 21
      Caption = 'V'#193'LASZD KI A MEGFELEL'#336'  TE'#193'OR SZ'#193'MOT'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 32
      Top = 306
      Width = 85
      Height = 19
      Caption = 'KERES'#201'S:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object TEAORRACS: TDBGrid
      Left = 32
      Top = 40
      Width = 449
      Height = 257
      Cursor = crHandPoint
      DataSource = ESOURCE
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = TEAORRACSDblClick
      OnKeyDown = TEAORRACSKeyDown
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'TEAOR'
          Title.Alignment = taCenter
          Title.Color = clYellow
          Title.Font.Charset = ANSI_CHARSET
          Title.Font.Color = clBlack
          Title.Font.Height = -16
          Title.Font.Name = 'Arial'
          Title.Font.Style = [fsBold]
          Width = 68
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'TEAORNEV'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Times New Roman'
          Font.Style = [fsItalic]
          Title.Alignment = taCenter
          Title.Caption = 'TEAOR NEGNEVEZ'#201'SE'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Arial'
          Title.Font.Style = [fsBold]
          Visible = True
        end>
    end
    object BitBtn1: TBitBtn
      Left = 376
      Top = 304
      Width = 113
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 1
      OnClick = BitBtn1Click
    end
    object KERESOEDIT: TEdit
      Left = 128
      Top = 306
      Width = 233
      Height = 27
      BorderStyle = bsNone
      Color = clBtnFace
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
  end
  object EQUERY: TIBQuery
    Database = EDBASE
    Transaction = ETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 184
    Top = 56
  end
  object EDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\TEAOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 224
    Top = 56
  end
  object ETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = EDBASE
    AutoStopAction = saNone
    Left = 264
    Top = 56
  end
  object ESOURCE: TDataSource
    DataSet = EQUERY
    Left = 312
    Top = 64
  end
end
