defmodule BankingApiWeb.Router do
  use BankingApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BankingApiWeb do
    pipe_through :api

    # User routers
    post "/users", UserController, :create
    get "/users/:id", UserController, :show

    # Account routers
    get "/accounts/:user_id", AccountController, :show

    # Operations routers
    post "/operations/withdrawals", OperationController, :withdrawal
    post "/operations/transactions", OperationController, :create_transaction
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: BankingApiWeb.Telemetry
    end
  end
end
