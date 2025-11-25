object Form2: TForm2
  Left = 427
  Top = 278
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 153
  ClientWidth = 329
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
  object HOVALASZ: TPanel
    Left = 0
    Top = 0
    Width = 329
    Height = 153
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 0
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 329
      Height = 153
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 4
    end
    object Label1: TLabel
      Left = 8
      Top = 16
      Width = 310
      Height = 22
      Caption = 'V'#193'LASZD KI A K'#205'V'#193'NT H'#211'NAPOT'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object EVCOMBO: TComboBox
      Left = 48
      Top = 64
      Width = 73
      Height = 30
      Cursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ItemHeight = 22
      ParentFont = False
      TabOrder = 0
      OnChange = EVCOMBOChange
    end
    object HOCOMBO: TComboBox
      Left = 120
      Top = 64
      Width = 177
      Height = 30
      Cursor = crHandPoint
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ItemHeight = 22
      ParentFont = False
      TabOrder = 1
      OnChange = EVCOMBOChange
    end
    object HOOKEGOMB: TBitBtn
      Left = 24
      Top = 112
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'H'#211'NAP RENDBEN'
      TabOrder = 2
      OnClick = HOOKEGOMBClick
    end
    object HOMEGSEMGOMB: TBitBtn
      Left = 168
      Top = 112
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 3
      OnClick = HOMEGSEMGOMBClick
    end
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 128
    Top = 40
  end
  object RECDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 168
    Top = 40
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 208
    Top = 40
  end
end
