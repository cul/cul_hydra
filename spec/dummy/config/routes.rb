Rails.application.routes.draw do

  mount Cul::Hydra::Engine => "/cul_hydra"
end
