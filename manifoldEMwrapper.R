require('dbscan')
require(igraph)
require(Rcpp)
sourceCpp('manifoldEMmod.cpp')
sourceCpp('nnrank.cpp')
sourceCpp('ccdist.cpp')
sourceCpp('geodist.cpp')


Manifold_EM = function(manifold_data, n_manifolds, knns, categories,max_iter){
  knng = kNN(manifold_data,knns)
  g <- make_empty_graph() %>%
    add_vertices(nrow(xall)) 
  for(i in 1:nrow(xall)){
    for(j in 1:knns){
      g = g+edges(c(i,knng$id[i,j]),weight = knng$dist[i,j])
    }
  }
  
  ccs = clusters(g)
  if (ccs$no == 1){
    geodist = distances(g,v=V(g),to = V(g),mode ='all',algorithm = 'dijkstra')
  }
  else{
    pathdist = distances(g,v=V(g),to = V(g),mode ='all',algorithm = 'dijkstra')
    l2dist = as.matrix(dist(manifold_data,method = 'euclidean'))
    ccdis = matrix(vector(length = (ccs$no)^2),ccs$no, ccs$no)
    ccrep = matrix(vector(length = (ccs$no)^2),ccs$no, ccs$no)
    for (i in 1:(ccs$no-1)){
      for (j in (i+1):ccs$no){
        temp_dist = as.matrix(l2dist[which(ccs$membership == i), which(ccs$membership == j)])
        min_pair = minccdist(temp_dist)
        
        ccdis[i,j] = temp_dist[(min_pair[1]+1),(min_pair[2]+1)]
        ccrep[j,i] = which(ccs$membership == j)[(min_pair[2]+1)]
        ccrep[i,j] = which(ccs$membership == i)[(min_pair[1]+1)]
      }
    }
    ccdis = ccdis + t(ccdis)
    geodist = geodist(pathdist,l2dist,ccdis,ccrep,ccs$membership)
    
  }
  nnrank = sigpointsampling(knng$id)
  initp = initialpointsamp(knng$id,nnrank,categories)
  cats = list();
  cats$cate = cats_EM(geodist,initp,n_manifolds,categories,max_iter)
  cats$initials = initp
  return(cats)
}