Rails.application.routes.draw do

  mount Cul::Scv::Hydra::Engine => "/cul_scv_hydra"
end
