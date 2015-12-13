library(scidb)
#scidbconnect("localhost", 8083, "scidb", "xxxx.xxxx.xxxx")
scidbconnect()
scidblist()
#########################################
######  subset and prepare scidb array ##
#########################################


# NOTE: Adjust the schema accordingly. Meng uses this query to remove overlap
# => remove overlap since data load
iquery("
       store(
       project(
       apply(
       repart(
       apply(
       subarray(
       repart(
       MOD09Q1_JUARA,
       <red:int16,nir:int16,quality:uint16> [col_id=57600:62399,502,5,row_id=48000:52799,502,5,time_id=0:9200,1,0]),
       58930,48210,6,59079,48359,643),
       evi2,2.5*((nir*0.0001-red*0.0001)/(nir*0.0001+2.4*red*0.0001+1.0))),
       <red:int16,nir:int16,quality:uint16,evi2:double>[col_id=0:149,1,1,row_id=0:149,1,1,time_id=0:637,638,0]),
       the_i,double(col_id),the_j,double(row_id),the_t,double(time_id)),
       the_i, the_j,the_t, evi2),
       repro1r)")

#############################################
######  perform sar epf (change detection) ##
#############################################
iquery("  store(r_exec( repro1r, 'output_attrs= 8',

       'expr=
       #sink(paste(\"/home/menglu/\",the_i[1],the_j[1],\".txt\" ))

       library(strucchange)
        library(bfast)
       library(spdep)
       library(nlme)

       data(X) # coefficient matrix
       data(listcn636) # neighbor


       dim1<-length(unique(the_i))
       dim2<-length(unique(the_j))
       dim3<-length(unique(the_t))
       tl=1:636
       w=1/46
       co <- cos(2*pi*tl*w)
       si <- sin(2*pi*tl*w)
       co2 <- cos(2*pi*tl*w*2)
       si2 <- sin(2*pi*tl*w*2)
       co3 <- cos(2*pi*tl*w*3)
       si3 <- sin(2*pi*tl*w*3)
       newarray1<-array(evi2,c(636, dim2,dim1))          # scidb array to r array
       newarray<-aperm(newarray1, c(3,2,1))

       fevi3b3<-filter.st.median2(newarray)

       #fevi3b3[is.na(fevi3b3)] <- 0
       #fevi3b3[fevi3b3>1]<- median(fevi3b3)
       #fevi3b3[fevi3b3<-1]<- median(fevi3b3)
       #aa2<-as.vector(fevi3b3)
       #aa2[aa2==0]<-NA
       #fevi3b3[fevi3b3==0]<- median(fevi3b3)



       if(dim1<3 || dim2<3)
{

       if(all(c(dim1==2,dim2 ==2))) # corner

{
       if(all(c(min(the_i)==0, min(the_j)==0)))
{
       fevi3b312t1<-ts(fevi3b3[1,1,],start=c(2000,1),frequency=46) # reconstruct the time series with its own
       rcol<-min(the_i)*1.0
       rrow<-max(the_j)*1.0
}         else if (all(c(min(the_i)==0, min(the_j)>0)))
{
       fevi3b312t1<-ts(fevi3b3[2,1,],start=c(2000,1),frequency=46) # reconstruct the time series with its own
       rcol<-min(the_i)*1.0
       rrow<-max(the_j)*1.0
}
       else if (all(c(min(the_i)>0,min(the_j)==0))) #upper right
{
       fevi3b312t1<-ts(fevi3b3[1,2,],start=c(2000,1),frequency=46) # reconstruct the time series with its own
       rcol<-max(the_i)*1.0
       rrow<-min(the_j)*1.0
}
       else if (all(c(min(the_i)>0,min(the_j)>0)))
{
       fevi3b312t1<-ts(fevi3b3[2,2,],start=c(2000,1),frequency=46) # reconstruct the time series with its own
       rcol<-max(the_i)*1.0
       rrow<-max(the_j)*1.0
}
} else if ( all(c(dim1==3, dim2==2,max(the_j)==1))) # row 1 #dim 1 is actually the length of j # side
{
       fevi3b312t1<-ts(fevi3b3[1,2,],start=c(2000,1),frequency=46) # reconstruct the time series with its own
       rcol<-(min(the_i)+1)*1.0
       rrow<-min(the_j)*1.0
}  else if (all(c( dim1==2, dim2==3  , max(the_i)==1))) #col 1
{
       fevi3b312t1<-ts(fevi3b3[2,1,],start=c(2000,1),frequency=46) # reconstruct the time series with its own
       rcol<-min(the_i)*1.0
       rrow<-(min(the_j)+1)*1.0
} else if (all(c( dim1==3  , dim2==2  ))) #col 149 # max(the_j)==149 is not needed
{
       fevi3b312t1<-ts(fevi3b3[2,2,],start=c(2000,1),frequency=46) # reconstruct the time series with its own
       rcol<-(min(the_i)+1)*1.0
       rrow<-max(the_j)*1.0
}else if (all(c( dim1==2, dim2==3  ))) #col 1 , max(the_i)==149
{
       fevi3b312t1<-ts(fevi3b3[2,2,],start=c(2000,1),frequency=46) # reconstruct the time series with its own
       rcol<-max(the_i)*1.0
       rrow<-(min(the_j)+1)*1.0
}


       resar1<-coredata(residuals(gls(fevi3b312t1 ~ tl+co+co2+co3+si+si2+si3,correlation=corAR1())))

       p.Vt3 <- sctest(efp(fevi3b312t1 ~  tl+co+co2+co3+si+si2+si3,   h = 0.15, type = \"OLS-CUSUM\" ))
       p.Vt4 <- sctest(efp(fevi3b312t1 ~  tl+co+co2+co3+si+si2+si3,   h = 0.15, type = \"OLS-MOSUM\" ))
       p.Vt5 <- sctest(efp(fevi3b312t1 ~  tl+co+co2+co3+si+si2+si3,   h = 0.15, type = \"OLS-CUSUM\" ,spatial1=as.numeric(resar1)) )
       p.Vt6 <- sctest(efp(fevi3b312t1 ~  tl+co+co2+co3+si+si2+si3,   h = 0.15, type = \"OLS-MOSUM\" ,spatial1=as.numeric(resar1)) )

       spcusum1<-p.Vt3$p.value*1.0 # spautolm residuals CUSUM
       spmosum1 <-p.Vt4$p.value*1.0 # spautolm residuals  MOSUM
       cusum1 <-p.Vt3$p.value*1.0 # CUSUM
       mosum1<-p.Vt4$p.value*1.0 # MOSUM
       cusumar1 <-p.Vt5$p.value*1.0 # CUSUM ar 1
       mosumar1 <-p.Vt6$p.value*1.0 # MOSUM ar1

}else {
       rcol <- (min(the_i)+1)*1.0
       rrow <- (min(the_j)+1)*1.0

       aa2<-as.vector(fevi3b3)
       fevi3b312t1<-ts(fevi3b3[2,2,],start=c(2000,1),frequency=46) # reconstruct the time series

       try2<-try(spautolm(aa2~. , data.frame(aa2,X),family=\"SAR\",method= \"Matrix\", listw=listcn636,na.action=na.exclude,zero.policy=TRUE))

       if(class(try2)==\"try-error\")
{
       spcusum1=-1.0
       spmosum1=-1.0
       cusum1=-1.0
       mosum1=-1.0
       cusumar1=-1.0
       mosumar1=-1.0
} else{

       rn<-lapply(1:9,function(i) {residuals(try2)[seq(i,636*9-(9-i),9)]})
       #get residuals for each time series

       ii<-5   # get the middle pixel (5 for 3*3 matrix)

       resar1<-coredata(residuals(gls(fevi3b312t1 ~ tl+co+co2+co3+si+si2+si3,correlation=corAR1())))

       p.Vt1  <- sctest(efp(fevi3b312t1 ~ tl+co+co2+co3+si+si2+si3,    h = 0.15, type = \"OLS-CUSUM\", spatial1=as.numeric(rn[[ii]]))  )
       p.Vt2  <- sctest(efp(fevi3b312t1 ~ tl+co+co2+co3+si+si2+si3,    h = 0.15, type = \"OLS-MOSUM\", spatial1=as.numeric(rn[[ii]]))  )
       p.Vt3 <-  sctest(efp(fevi3b312t1 ~  tl+co+co2+co3+si+si2+si3,   h = 0.15, type = \"OLS-CUSUM\" ))
       p.Vt4 <-  sctest(efp(fevi3b312t1 ~  tl+co+co2+co3+si+si2+si3,   h = 0.15, type = \"OLS-MOSUM\" ))
       p.Vt5 <-  sctest(efp(fevi3b312t1 ~  tl+co+co2+co3+si+si2+si3,   h = 0.15, type = \"OLS-CUSUM\" ,spatial1=as.numeric(resar1)) )
       p.Vt6 <-  sctest(efp(fevi3b312t1 ~  tl+co+co2+co3+si+si2+si3,   h = 0.15, type = \"OLS-MOSUM\" ,spatial1=as.numeric(resar1)) )

       spcusum1  <-p.Vt1$p.value*1.0 # spautolm residuals CUSUM
       spmosum1  <-p.Vt2$p.value*1.0 # spautolm residuals  MOSUM
       cusum1    <-p.Vt3$p.value*1.0 # CUSUM
       mosum1    <-p.Vt4$p.value*1.0# MOSUM
       cusumar1 <-p.Vt5$p.value*1.0 # CUSUM ar 1
       mosumar1 <-p.Vt6$p.value*1.0 # MOSUM ar1
        }

}

       list(spcusum1, spmosum1,cusum1,mosum1,cusumar1,mosumar1,rcol,rrow  )

       '), outputsar150f2)",
       return=TRUE
       )


#spcusum1, spmosum1,cusum1,mosum1,cusumar1,mosumar1,rcol,rrow

#  iquery("show(resarefpscidbf2)",return=TRUE,n=10)
#################################################
######  restore the output array to SciDB array##
#################################################
#Restore the dimensions (attribute double to int64, then redimension)
 iquery("store(
  redimension(
  subarray(  project(
      apply(
        attribute_rename(
          project(
            unpack(outputsar150f2, tmpDim) ,
            expr_value_0,expr_value_1,expr_value_2,expr_value_3,expr_value_4,expr_value_5
            ,expr_value_6,expr_value_7
          ),
          expr_value_0, spcu, expr_value_1,spmo, expr_value_2,cu, expr_value_3, mo,
          expr_value_4,arcu,expr_value_5,armo,expr_value_6,thecol,expr_value_7,therow
        ),
        col1, int64(thecol), row1, int64(therow)
      ),
       col1,row1, spcu,spmo,cu,mo,arcu,armo
    ), 0,22499),
    <spcu:double, spmo:double, cu: double,mo:double, arcu:double,armo:double> [col1=0:149,3,0, row1=0:149,3,0]
  ), resarefpscidbf03)",return=TRUE)

#iquery("dimensions(resarefpscidbf02)",return=TRUE)
# mind the name has to match!!

#resarefpscidb2
#iquery("store(

#    project(
#      apply(
#        attribute_rename(
#          project(
#            unpack(outputsar150f2, tmpDim) ,
#            expr_value_0,expr_value_1,expr_value_2,expr_value_3,expr_value_4,expr_value_5
#            ,expr_value_6,expr_value_7
#          ),
#          expr_value_0, spcu, expr_value_1,spmo, expr_value_2,cu, expr_value_3, mo,
#          expr_value_4,arcu,expr_value_5,armo,expr_value_6,thecol,expr_value_7,therow
 #       ),
#        col1, int64(thecol), row1, int64(therow)
#      ),
#       col1,row1, spcu,spmo,cu,mo,arcu,armo
#    ), resarefpscidbf2t)",return=TRUE)
#iquery("dimensions(resarefpscidbf2t)",return=TRUE)
#r1<-scidb("resarefpscidbf2t")
#summary(r1[])
#x1<-r1[]$row1
#y1<-r1[]$col1
#v1<-r1[]$mo
#t1<-data.frame(cbind(x1,y1,v1))

#coordinates(t1)<-~x1+y1
#t11<-raster(t1)
#t2<-  subset(t1,t1["v1"]<0.05,select = c(1, 2,3))
#par(mfrow=c(1,2))
#spplot(t2)
#spplot(raster(tssarar4)<0.05)
# gridded(t1)<-TRUE
#spplot(raster(t1)<0.05)
