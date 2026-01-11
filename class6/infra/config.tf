locals {
  srvices =[

   { name = "frontend",
    port = 80 
    repo = "eks-3-tier-frontend"
    },
   {  name = "backend",
      port = 8080 
      repo = "eks-3-tier-frontend"
    },
  ]
}