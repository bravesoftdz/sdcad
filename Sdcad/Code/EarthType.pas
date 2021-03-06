unit EarthType;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids, Buttons, DB, OleCtrls,
  ExtCtrls, Mask, rxToolEdit, rxCurrEdit;

type
  TEarthTypeForm = class(TForm)
    lbl_qiymc: TLabel;
    btn_ok: TBitBtn;
    btn_cancel: TBitBtn;
    Gbox: TGroupBox;
    sgEarthType: TStringGrid;
    gbox2: TGroupBox;
    lblD_t_no: TLabel;
    lblD_t_name: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    edtEa_name: TEdit;
    edtAge: TEdit;
    edtEa_no: TCurrencyEdit;
    edtEa_name_en: TEdit;
    btn_add: TBitBtn;
    btn_delete: TBitBtn;
    btn_edit: TBitBtn;
    procedure sgEarthTypeSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure btn_cancelClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btn_deleteClick(Sender: TObject);
    procedure btn_addClick(Sender: TObject);
    procedure btn_editClick(Sender: TObject);
    procedure btn_okClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edtEa_noKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
    procedure button_status(int_status:integer;bHaveRecord:boolean);
    procedure Get_oneRecord(aEarthNo: String);
    function Delete_oneRecord(strSQL:string):boolean;
    function Update_oneRecord(strSQL:string):boolean;
    function Insert_oneRecord(strSQL:string):boolean;
    function GetInsertSQL:string;
    function GetUpdateSQL:string;
    function GetDeleteSQL:string;
    function Check_Data:boolean;
    function isExistedRecord(aEarthNo:string):boolean;
  public
    { Public declarations }
  end;

type
  TEarthRecord=Record
    ea_no:String;
    ea_name:string;
    ea_name_en:string;
    age:string;
  end;
var
  EarthTypeForm: TEarthTypeForm;
  m_iGridSelectedRow: integer;
  m_DataSetState: TDataSetState;
  m_EarthRecord: TEarthRecord;
implementation

uses MainDM, public_unit;

{$R *.dfm}

procedure TEarthTypeForm.button_status(int_status: integer;
  bHaveRecord: boolean);
begin
  case int_status of
    1: //浏览状态
      begin
        btn_edit.Enabled :=bHaveRecord;
        btn_delete.Enabled :=bHaveRecord;
        btn_edit.Caption :='修改';
        btn_ok.Enabled :=false;
        btn_add.Enabled :=true;
        Enable_Components(self,false);
        m_DataSetState := dsBrowse;
      end;
    2: //修改状态
      begin
        btn_edit.Enabled :=true;
        btn_edit.Caption :='放弃';
        btn_ok.Enabled :=true;
        btn_add.Enabled :=false;
        btn_delete.Enabled :=false;
        Enable_Components(self,true);
        m_DataSetState := dsEdit;
      end;
    3: //增加状态
      begin
        btn_edit.Enabled :=true;
        btn_edit.Caption :='放弃';
        btn_ok.Enabled :=true;
        btn_add.Enabled :=false;
        btn_delete.Enabled :=false;
        Enable_Components(self,true);
        m_DataSetState := dsInsert;
      end;
  end;
end;

function TEarthTypeForm.Check_Data: boolean;
begin
  if trim(edtEa_no.Text) = '' then
  begin
    messagebox(self.Handle,'请输入土类代码！','数据校对',mb_ok);
    edtEa_no.SetFocus;
    result := false;
    exit;
  end;
  if trim(edtEa_name.Text) = '' then
  begin
    messagebox(self.Handle,'请输入土类名称！','数据校对',mb_ok);
    edtEa_name.SetFocus;
    result := false;
    exit;
  end;
  result := true;
end;

function TEarthTypeForm.Delete_oneRecord(strSQL: string): boolean;
begin
  with MainDataModule.qryEarthType do
    begin
      close;
      sql.Clear;
      sql.Add(strSQL);

      try
        try
          ExecSQL;
          MessageBox(self.Handle,'删除成功！','删除数据',MB_OK+MB_ICONINFORMATION);
          result := true;
        except
          MessageBox(self.Handle,'数据库错误，不能删除所选数据。','数据库错误',MB_OK+MB_ICONERROR);
          result := false;
        end;
      finally
        close;
      end;
    end;
end;


procedure TEarthTypeForm.Get_oneRecord(aEarthNo: String);
begin
  if aEarthNo='' then exit;
  with MainDataModule.qryEarthType do
    begin
      close;
      sql.Clear;
      sql.Add('SELECT ea_no,ea_name,ea_name_en,age FROM earthtype ');
      sql.Add(' WHERE ea_no=' + ''''+aEarthNo+'''');  
      open;
      
      while not Eof do
      begin 
        edtEa_no.Text   := FieldByName('ea_no').AsString;
        edtEa_name.Text := FieldByName('ea_name').AsString;
        edtEa_name_en.Text := FieldByName('ea_name_en').AsString;
        edtAge.Text     := FieldByName('age').AsString;
        m_EarthRecord.age := edtAge.Text;
        m_EarthRecord.ea_no := edtEa_no.Text;
        m_EarthRecord.ea_name := edtEa_name.Text ;
        m_EarthRecord.ea_name_en := edtEa_name_en.Text;
        next;
      end;
      close;
    end;  
end;

function TEarthTypeForm.GetDeleteSQL: string;
begin
  result :='DELETE FROM earthtype WHERE ea_no='+ ''''+edtEa_no.Text+'''';
end;

function TEarthTypeForm.GetInsertSQL: string;
begin
  if trim(edtAge.Text)='' then
    result := 'INSERT INTO earthtype (ea_no,ea_name,ea_name_en) VALUES('
            +''''+trim(edtEa_no.Text)+''''+','
            +''''+trim(edtEa_name.Text)+''''+','
            +''''+trim(edtEa_name_en.Text)+''')'
  else
    result := 'INSERT INTO earthtype (ea_no,ea_name,ea_name_en,age) VALUES('
            +''''+trim(edtEa_no.Text)+''''+','
            +''''+trim(edtEa_name.Text)+''''+','
            +''''+trim(edtEa_name_en.Text)+''''+','
            +''''+trim(edtAge.Text)+''')';

end;

function TEarthTypeForm.GetUpdateSQL: string;
var 
  strSQLWhere,strSQLSet:string;
begin
  strSQLWhere:=' WHERE ea_no='+''''+sgEarthType.Cells[1,sgEarthType.Row]+'''';
  strSQLSet:='UPDATE earthtype SET '; 
  strSQLSet := strSQLSet + 'ea_no' +'='+''''+trim(edtEa_no.Text)+''''+',';
  strSQLSet := strSQLSet + 'ea_name' +'='+''''+trim(edtEa_name.Text)+''''+',';
  strSQLSet := strSQLSet + 'ea_name_en' +'='+''''+trim(edtEa_name_en.Text)+''''+',';
  strSQLSet := strSQLSet + 'age' +'='+''''+trim(edtAge.Text)+'''';
  result := strSQLSet + strSQLWhere;
end;

function TEarthTypeForm.Insert_oneRecord(strSQL: string): boolean;
begin
  with MainDataModule.qryEarthType do
    begin
      close;
      sql.Clear;
      sql.Add(strSQL);
      try
        try
          ExecSQL;
          MessageBox(self.Handle,'增加数据成功！','增加数据',MB_OK+MB_ICONINFORMATION);
          result := true;
        except
          MessageBox(self.Handle,'数据库错误，增加数据失败。','数据库错误',MB_OK+MB_ICONERROR);
          result:= false;
        end;
      finally
        close;
      end;
    end;
end;

function TEarthTypeForm.isExistedRecord(aEarthNo: string): boolean;
begin
  with MainDataModule.qryEarthType do
    begin
      close;
      sql.Clear;
      sql.Add('SELECT ea_no FROM earthtype ');
      sql.Add(' WHERE ea_no=' + ''''+aEarthNo+'''' );
      try
        try
          Open;
          if eof then 
            result:=false
          else
          begin
            result:=true;
            messagebox(self.Handle,'此类别代码已经存在，请输入新的类别代码！','数据校对',mb_ok);  
            edtEa_no.SetFocus;
          end;
        except
          result:=false;
        end;
      finally
        close;
      end;
    end;
end;

function TEarthTypeForm.Update_oneRecord(strSQL: string): boolean;
begin
  with MainDataModule.qryEarthType do
    begin
      close;
      sql.Clear;
      sql.Add(strSQL);
      try
        try
          ExecSQL;
          MessageBox(self.Handle,'更新数据成功！','更新数据',MB_OK+MB_ICONINFORMATION);
          result := true;
        except
          MessageBox(self.Handle,'数据库错误，更新数据失败。','数据库错误',MB_OK+MB_ICONERROR);
          result:= false;
        end;
      finally
        close;
      end;
    end;
end;

procedure TEarthTypeForm.sgEarthTypeSelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin
  if sgEarthType.Tag =1 then exit;
  if (ARow <>0) and (ARow<>m_iGridSelectedRow) then
    if sgEarthType.Cells[1,ARow]<>'' then
    begin
      Get_oneRecord(sgEarthType.Cells[1,ARow]);
      if sgEarthType.Cells[1,ARow]='' then
        Button_status(1,false)
      else
        Button_status(1,true);
    end
    else
    begin
      clear_data(self);
    end;
  m_iGridSelectedRow:=ARow;  
end;

procedure TEarthTypeForm.btn_cancelClick(Sender: TObject);
begin
  self.Close;
end;

procedure TEarthTypeForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TEarthTypeForm.btn_deleteClick(Sender: TObject);
var
  strSQL: string;
begin
  if MessageBox(self.Handle,
    '您确定要删除吗？','警告', MB_YESNO+MB_ICONQUESTION)=IDNO then exit;
  if edtEa_no.Text <> '' then
    begin
      strSQL := self.GetDeleteSQL;
      if Delete_oneRecord(strSQL) then
        begin
          Clear_Data(self);
          DeleteStringGridRow(sgEarthType,sgEarthType.Row);
          self.Get_oneRecord(sgEarthType.Cells[1,sgEarthType.Row]);
          if sgEarthType.Cells[1,sgEarthType.row]='' then
            button_status(1,false)
          else
            button_status(1,true);
        end;
    end;
end;

procedure TEarthTypeForm.btn_addClick(Sender: TObject);
begin
  Clear_Data(self);
  m_EarthRecord.age     := '';
  m_EarthRecord.ea_no   := '';
  Button_status(3,true);
  edtEa_no.SetFocus;
  edtEa_no.ReadOnly := false;
end;

procedure TEarthTypeForm.btn_editClick(Sender: TObject);
begin
  if btn_edit.Caption ='修改' then
  begin
    Button_status(2,true);
  end
  else
  begin
    clear_data(self);
    Button_status(1,true);
    self.Get_oneRecord(sgEarthType.Cells[1,sgEarthType.Row]);
  end;
end;

procedure TEarthTypeForm.btn_okClick(Sender: TObject);
var
  strSQL: string;
begin
  if not Check_Data then exit;
  if m_DataSetState = dsInsert then
    begin
      if isExistedRecord(trim(edtEa_no.Text)) then exit;
      strSQL := self.GetInsertSQL;
      if Insert_oneRecord(strSQL) then
        begin
          if (sgEarthType.RowCount =2) and (sgEarthType.Cells[1,1] ='') then
          else
            sgEarthType.RowCount := sgEarthType.RowCount+1;
          m_iGridSelectedRow:= sgEarthType.RowCount-1;
          sgEarthType.Cells[1,sgEarthType.RowCount-1] := trim(edtEa_no.Text);
          sgEarthType.Cells[2,sgEarthType.RowCount-1] := trim(edtEa_name.Text);
          sgEarthType.Row := sgEarthType.RowCount-1;
          Button_status(1,true);
          btn_add.SetFocus;
          edtEa_no.ReadOnly := true;
        end;
    end
  else if m_DataSetState = dsEdit then
    begin
      if sgEarthType.Cells[1,sgEarthType.Row]<>trim(edtEa_no.Text) then
        if isExistedRecord(trim(edtEa_no.Text)) then exit;
        strSQL := self.GetUpdateSQL;        
        if self.Update_oneRecord(strSQL) then
          begin
            sgEarthType.Cells[1,sgEarthType.Row] := edtEa_no.Text ;
            sgEarthType.Cells[2,sgEarthType.Row] := edtEa_name.Text ;
            Button_status(1,true);
            btn_add.SetFocus;
          end;      
    end;

end;

procedure TEarthTypeForm.FormCreate(Sender: TObject);
var
  i: integer;
begin

  self.Left := trunc((screen.Width -self.Width)/2);
  self.Top  := trunc((Screen.Height - self.Height)/2);
  sgEarthType.RowHeights[0] := 16;
  sgEarthType.Cells[1,0] := '土类代码';  
  sgEarthType.Cells[2,0] := '土类名称';
  sgEarthType.ColWidths[0]:=10;
  sgEarthType.ColWidths[1]:=125;
  sgEarthType.ColWidths[2]:=125;
  
  m_iGridSelectedRow:= -1;

  Clear_Data(self);
  with MainDataModule.qryEarthType do
    begin
      close;
      sql.Clear;
      sql.Add('SELECT ea_no,ea_name,age FROM earthtype');
      open;
      i:=0;
      sgEarthType.Tag :=1;
      while not Eof do
        begin
          i:=i+1;
          sgEarthType.RowCount := i +1;
          sgEarthType.Cells[1,i] := FieldByName('ea_no').AsString;  
          sgEarthType.Cells[2,i] := FieldByName('ea_name').AsString;
          Next ;
        end;
      close;
      sgEarthType.Tag :=0;
    end;
  if i>0 then
  begin
    sgEarthType.Row :=1;
    m_iGridSelectedRow :=1;
    Get_oneRecord(sgEarthType.Cells[1,sgEarthType.Row]);
    button_status(1,true);
  end
  else
    button_status(1,false);
end;

procedure TEarthTypeForm.edtEa_noKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  change_focus(key,self);
end;

end.
