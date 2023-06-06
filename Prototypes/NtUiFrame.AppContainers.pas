unit NtUiFrame.AppContainers;

{
  This module provides a frame for showing a list of AppContainer profiles.
}

interface

uses
  Vcl.Controls, System.Classes, Vcl.Forms, VirtualTrees, VirtualTreesEx,
  DevirtualizedTree, NtUiFrame.Search, NtUtils, NtUiCommon.Interfaces;

type
  TAppContainersFrame = class (TFrame, IHasSearch, ICanConsumeEscape,
    IGetFocusedNode, IOnNodeSelection)
  published
    SearchBox: TSearchFrame;
    Tree: TDevirtualizedTree;
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
    property BackendImpl: TTreeNodeInterfaceProvider read Backend implements IGetFocusedNode, IOnNodeSelection;
    property SearchImpl: TSearchFrame read SearchBox implements IHasSearch, ICanConsumeEscape;
  protected
    procedure Loaded; override;
  public
    procedure LoadForUser(const User: ISid);
  end;

implementation

uses
  NtUiBackend.AppContainers;

{$R *.dfm}

{ TAppContainersFrame }

procedure TAppContainersFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree, [teSelectionChange]);
  BackendRef := Backend; // Make an owning reference
end;

procedure TAppContainersFrame.LoadForUser;
var
  Parents, Children: TArray<IAppContainerNode>;
  Parent, Child: IAppContainerNode;
  Status: TNtxStatus;
begin
  // Enumerate parent AppContainers
  Status := UiLibEnumerateAppContainers(Parents, User);
  Backend.SetStatus(Status);

  if not Status.IsSuccess then
    Exit;

  Backend.BeginUpdateAuto;
  Backend.ClearItems;

  for Parent in Parents do
  begin
    Backend.AddItem(Parent);

    // Enumerate child AppContainers
    if UiLibEnumerateAppContainers(Children, User, Parent.Info.Sid).IsSuccess then
      for Child in Children do
        Backend.AddItem(Child, Parent);
  end;
end;

end.
