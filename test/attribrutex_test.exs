defmodule AttribrutexTest do
  use ExUnit.Case

  doctest Attribrutex

  @repo Attribrutex.RepoClient.repo

  setup do
    @repo.delete_all(Attribrutex.CustomField)
    :ok
  end

  test "create_custom_field/4" do
    {status, resource} =
      Attribrutex.create_custom_field("sample", :string, AttribrutexUser)

    assert status == :ok
    assert resource.key == "sample"
    assert resource.field_type == :string
    assert resource.fieldable_type == "AttribrutexUser"
  end

  test "create_custom_field/4 with context" do
    {status, resource} =
      Attribrutex.create_custom_field("sample", :string, AttribrutexUser, context_id: 1, context_type: "User")

    assert status == :ok
    assert resource.key == "sample"
    assert resource.field_type == :string
    assert resource.fieldable_type == "AttribrutexUser"
    assert resource.context_id == 1
    assert resource.context_type == "User"
  end

  test "list_custom_fields_for/2" do
    Attribrutex.create_custom_field("stuff", :integer, User)

    result = Attribrutex.list_custom_fields_for(User)
    custom_field = Enum.at(result, 0)

    assert length(result) == 1
    assert custom_field.__struct__ == Attribrutex.CustomField
  end

  test "list_custom_fields_for/2 with context" do
    Attribrutex.create_custom_field("stuff", :integer, User)
    Attribrutex.create_custom_field("location", :integer, User, context_id: 1, context_type: "User")

    result = Attribrutex.list_custom_fields_for(User, %{context_id: 1, context_type: "User"})
    custom_field = Enum.at(result, 0)

    assert length(result) == 1
    assert custom_field.key == "location"
  end

  test "list_custom_fields_for/2 with :keys mode" do
    Attribrutex.create_custom_field("stuff", :integer, User)

    result = Attribrutex.list_custom_fields_for(User, %{mode: :keys})
    custom_field = Enum.at(result, 0)

    assert length(result) == 1
    assert custom_field == "stuff"
  end

  test "list_custom_fields_for/2 with :fields mode" do
    Attribrutex.create_custom_field("stuff", :integer, User)

    result = Attribrutex.list_custom_fields_for(User, %{mode: :fields})
    custom_field = Enum.at(result, 0)

    assert length(result)    == 1
    assert custom_field.key  == "stuff"
    assert custom_field.type == :integer
  end

  test "prepare_custom_fields/3 with valid attributes" do
    Attribrutex.create_custom_field("location", :string, AttribrutexUser)
    changeset = AttribrutexUser.changeset(%AttribrutexUser{}, %{email: "asdf@asdf.com"})

    changeset = Attribrutex.prepare_custom_fields(changeset, %{"location" => "Madrid"})
    {_, result} = @repo.insert(changeset)

    assert changeset.changes.custom_fields.location == "Madrid"
    assert result.email == "asdf@asdf.com"
    assert result.custom_fields.location == "Madrid"
  end

  test "prepare_custom_fields/3 with invalid attributes" do
    Attribrutex.create_custom_field("location", :string, AttribrutexUser)
    changeset = AttribrutexUser.changeset(%AttribrutexUser{}, %{email: "asdf@asdf.com"})

    changeset = Attribrutex.prepare_custom_fields(changeset, %{"location" => 23})
    {status, _} = @repo.insert(changeset)

    refute changeset.valid?
    assert status == :error
  end

  test "prepare_custom_fields/3 with context" do
    Attribrutex.create_custom_field("location", :string, AttribrutexUser, context_id: 1, context_type: "User" )
    changeset = AttribrutexUser.changeset(%AttribrutexUser{}, %{email: "asdf@asdf.com"})

    changeset = Attribrutex.prepare_custom_fields(changeset, %{"location" => "Madrid"}, %{context_id: 1, context_type: "User"})
    {_, result} = @repo.insert(changeset)

    assert changeset.changes.custom_fields.location == "Madrid"
    assert result.email == "asdf@asdf.com"
    assert result.custom_fields.location == "Madrid"
  end

  test "prepare_custom_fields/3 with bad context" do
    Attribrutex.create_custom_field("location", :string, AttribrutexUser, context_id: 1, context_type: "User" )
    changeset = AttribrutexUser.changeset(%AttribrutexUser{}, %{email: "asdf@asdf.com"})

    changeset = Attribrutex.prepare_custom_fields(changeset, %{"location" => "Madrid"}, %{context_id: 1, context_type: "Location"})
    {_, result} = @repo.insert(changeset)

    assert result.email == "asdf@asdf.com"
    assert result.custom_fields == %{}
  end

  test "prepare_custom_fields/3 from model changeset" do
    Attribrutex.create_custom_field("location", :string, AttribrutexUser)
    changeset = AttribrutexUser.custom_fields_changeset(%AttribrutexUser{}, %{"email" => "asdf@asdf.com", "location" => "Madrid"})
    {_, result} = @repo.insert(changeset)
    assert changeset.changes.custom_fields.location == "Madrid"
    assert result.email == "asdf@asdf.com"
    assert result.custom_fields.location ==  "Madrid"
  end

  test "prepare_custom_fields/3 from model changeset filters not present params" do
    {_, result} = @repo.insert(AttribrutexUser.custom_fields_changeset(%AttribrutexUser{}, %{"email" => "asdf@asdf.com", "location" => "Madrid"}))
    assert result.email == "asdf@asdf.com"
    assert result.custom_fields == %{}
  end

  test "prepare_custom_fields/3 from model changeset works on update" do
    Attribrutex.create_custom_field("location", :string, AttribrutexUser)
    {_, struct} = @repo.insert(AttribrutexUser.custom_fields_changeset(%AttribrutexUser{}, %{"email" => "asdf@asdf.com", "location" => "Madrid"}))

    {_, result} = @repo.update(AttribrutexUser.custom_fields_changeset(struct, %{"email" => "update@update.com", "location" => "Brasil"}))

    assert result.email == "update@update.com"
    assert result.custom_fields.location == "Brasil"
  end

end
