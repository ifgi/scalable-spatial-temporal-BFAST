#library(devtools)
 
#install_github("strucchange","mengluchu",build_vignettes = FALSE)
#load("fevi8.Rdata")
#library(strucchange)
#library(spacetime) 
#library(spdep)
#library(nlme)

SARefpdents<-function( inputarray=fevi8,le=636)
{  
  
  tl=1:le
  
  w=1/46
  #harmonic
  co <- cos(2*pi*tl*w); si <- sin(2*pi*tl*w)
  co2 <- cos(2*pi*tl*w*2);si2 <- sin(2*pi*tl*w*2)  
  co3 <- cos(2*pi*tl*w*3);si3 <- sin(2*pi*tl*w*3) 
  #season1<-lm(cmonmean~co+co2++co3+si+si2+si3)
  
  # get neighbor
  
  eday <- as.Date("2000-01-30")           # date 
  e8day <- seq(eday, length.out=636, by="8 days")
  xyd<-expand.grid(x1=1:3,y1=1:3)
  coordinates(xyd)<-~x1+y1
  lecube<-3*3*636
  aa3<-as.data.frame(c(1:lecube))
  stfdf3b3<-STFDF(xyd,e8day,aa3) ## for creating neighbors only, aa3 could be any data?
  cn<-cell2nb(3,3, type ="queen",torus =FALSE)
  
  neigh1<-nbMult(cn, stfdf3b3, addT = FALSE, addST = FALSE) # only spatial neighbours are added for each time step
  listcn636<-nb2listw(neigh1)
  #
  X = matrix(0, 636 * 9, 9*8)
  
  for( i in 1:9)
  {
    
    X[seq(i,by=9,length.out=636),1+(i-1)*8] = 1 
    X [seq(i,by=9,length.out=636),2+(i-1)*8] = tl 
    X[seq(i,by=9,length.out=636),3+(i-1)*8] =co
    X[seq(i,by=9,length.out=636),4+(i-1)*8] =co2
    X[seq(i,by=9,length.out=636),5+(i-1)*8] =co3
    X[seq(i,by=9,length.out=636),6+(i-1)*8] =si
    X[seq(i,by=9,length.out=636),7+(i-1)*8] =si2
    X[seq(i,by=9,length.out=636),8+(i-1)*8] =si3
  }
  
  
  colnames(X) = paste0("v", 1:(9*8))
  
  tssarar1<-array(,c(148,148))
  tssarar2<-array(,c(148,148))
  tssarar3<-array(,c(148,148))
  tssarar4<-array(,c(148,148))
  tssarar5<-array(,c(148,148))
  tssarar6<-array(,c(148,148))
  
  dimx<-dim(inputarray)[1]-2
  dimy<-dim(inputarray)[2]-2
  for(i in 1:dimx)
  {
    for (j in 1:dimy)
    {
      
      f2<-inputarray[i:(i+2),j:(j+2),]
      
      fevi3b312t1<-ts(f2[2,2,],start=c(2000,1),frequency=46) # reconstruct the time series
      
      aa2<-as.vector(f2) 
      try2<-spautolm(aa2~. , data.frame(aa2,X),family="SAR",method= "Matrix", listw=listcn636)   
      
      rn<-lapply(1:9,function(i) {residuals(try2)[seq(i,636*9-(9-i),9)]})
      
      resar1<-coredata(residuals(gls(fevi3b312t1 ~ tl+co+co2+co3+si+si2+si3,correlation=corAR1())))
      
      #get residuals for each time series
      
      ii<-5   # get the middle pixel (5 for 3*3 matrix)
      
      p.Vt1  <- sctest(efp(fevi3b312t1 ~ tl+co+co2+co3+si+si2+si3, h = 0.15, type = "OLS-CUSUM", spatial1=as.numeric(rn[[ii]]))  )
      p.Vt2  <- sctest(efp(fevi3b312t1 ~ tl+co+co2+co3+si+si2+si3, h = 0.15, type = "OLS-MOSUM", spatial1=as.numeric(rn[[ii]]))  )
      p.Vt3 <- sctest(efp(fevi3b312t1 ~  tl+co+co2+co3+si+si2+si3,   h = 0.15, type = "OLS-CUSUM" )) 
      p.Vt4 <- sctest(efp(fevi3b312t1 ~  tl+co+co2+co3+si+si2+si3, h = 0.15, type = "OLS-MOSUM" ))
      p.Vt5 <- sctest(efp(fevi3b312t1 ~  tl+co+co2+co3+si+si2+si3,   h = 0.15, type = "OLS-CUSUM" ,spatial1=as.numeric(resar1)) ) 
      p.Vt6 <- sctest(efp(fevi3b312t1 ~  tl+co+co2+co3+si+si2+si3, h = 0.15, type = "OLS-MOSUM" ,spatial1=as.numeric(resar1)) )
      
      tssarar1[i,j]<-p.Vt1$p.value # spautolm residuals CUSUM
      tssarar2[i,j]<-p.Vt2$p.value # spautolm residuals  MOSUM  
      tssarar3[i,j] <-p.Vt3$p.value # CUSUM
      tssarar4[i,j] <-p.Vt4$p.value # MOSUM
      tssarar5[i,j] <-p.Vt5$p.value # CUSUM ar 1
      tssarar6[i,j] <-p.Vt6$p.value # MOSUM ar1
      
      
    }
  }
  
  #save(tssarar1,file="tssarar1.Rdata")
  #save(tssarar2,file="tssarar2.Rdata")
  #save(tssarar3,file="tssarar3.Rdata")
  #save(tssarar4,file="tssarar4.Rdata")
  #save(tssarar5,file="tssarar5.Rdata")
  #save(tssarar6,file="tssarar6.Rdata")
  
  
  tsall<-list(tssarar1,tssarar2,tssarar3,tssarar4,tssarar5,tssarar6)
  names(tsall)<-c("sarcusum","sarmosum","cusum","mosum","cusum","mosum")
  return(tsall)
}
#tssarar1<-tsall[[1]]
#tssarar2<-tsall[[2]]
#tssarar3<-tsall[[3]]
#tssarar4<-tsall[[4]]
#tssarar5<-tsall[[5]]
#tssarar6<-tsall[[6]]SARefpdents