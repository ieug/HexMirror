defmodule HexWeb.PackageDownload do
  use HexWeb.Web, :model
  import HexWeb.QueryAPI, only: [coalesce: 2]

  @primary_key false

  schema "package_downloads" do
    belongs_to :package, Package, references: :id
    field :view, :string
    field :downloads, :integer
  end

  # TODO: Figure out a place to move this
  def refresh do
    Ecto.Adapters.SQL.query(
       HexWeb.Repo,
       "REFRESH MATERIALIZED VIEW package_downloads",
       [])
  end

  def top(view, count) do
    from(pd in PackageDownload,
         join: p in assoc(pd, :package),
         where: not is_nil(pd.package_id) and pd.view == ^view,
         order_by: [desc: pd.downloads],
         limit: ^count,
         select: {p.name, pd.downloads})
  end

  def total do
    from(pd in PackageDownload,
         where: is_nil(pd.package_id),
         select: {pd.view, coalesce(pd.downloads, 0)})
  end

  def package(package) do
    from(pd in PackageDownload,
         where: pd.package_id == ^package.id,
         select: {pd.view, coalesce(pd.downloads, 0)})
  end

  def packages(packages, view) do
    package_ids = Enum.map(packages, &(&1.id))

    from(pd in PackageDownload,
         join:   p in assoc(pd, :package),
         where:  pd.package_id in ^package_ids,
         where:  pd.view == ^view,
         select: {p.id, pd.downloads})
  end
end
