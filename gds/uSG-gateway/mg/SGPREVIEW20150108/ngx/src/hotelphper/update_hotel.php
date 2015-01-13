<?php if (!defined('BASEPATH')) exit('No direct script access allowed');

/**
 *
 *
 *
 */
class Update_hotel extends CI_Model
{
    //星期的数字数组
     private $week_set;

    public function __construct()
    {
        parent::__construct();
        $this->load->database();
        $this->load->config();
        $this->week_set = array(1,2,3,4,5,6,7);
    }
    /**
     *  更新价格
     *
     *  {"addBed":-1,"changeID":0,"city":"SZX","currencyCode":"RMB",
     * "endDate":"2014-08-15 00:00:00","hotelID":"90180497","hotelIdMG":30000328,
     * "lastId":2084688271,"member":10998.9,"memberCost":-1,"priceID":1374265282,
     * "ratePlanIdMG":58467,"rateplanId":408749,"roomTypeId":"0001","roomTypeIdMG":98440,
     * "startDate":"2014-08-15 00:00:00","status":true,"time":"2014-07-02 10:51:00",
     * "week_end":0,"week_start":0,"weekend":10998.9,"weekendCost":-1}
     *
     * 判断逻辑
     * status为false时，数据库售价字段SALEPRICE置0，置关房标志"G",
     * status为true时, 逐条取startDate至endDate中的每一天，且将这天转换成星期几$weekindex = (1-7)，且这天要作为更新表的条件
     * 若$weekindex在week_start和week_end之间，则酒店价格SALEPRICE应该取weekend，否则酒店价格SALEPRICE应该取member
     * 且要置关房标志空"",
     * status为true时，但价格为0时，当做status为空处理
     *
     *  update set 字段
     * SALEPRICE 售价 $member  ((在不可卖时,变为 0)
     * CLOSEFLAG 开关状态 (在不可卖时，变为"G"，可卖时，变为"")
     * HASBOOK  可预订 0/1
     *
     *
     * where condition
     * 左边Oracle数据库字段，中间位字段描述，右边服务器缓存json数据的字段
     * ABLEDATE  日期  从$startDate 和$endDate 中抽离出来
     * COMMODITYID 商品ID(价格计划ID )  $ratePlanIdMG
     * ROOMTYPEID 房型ID $roomTypeIdMG
     * HOTELID 酒店Id，$hotelIdMG
     *
     *
     * 一天的滴答数 = 86400
     */
   public function  hotel_price_update($price_string,$NeedlogTable){
     //  $price_string = utf8_encode($price_string);
       $price_arr = json_decode($price_string,true);

       if(!is_array($price_arr)){
           return false;
       }
      // $start = microtime(true);
       try{

           //判断更新数据库是否成功，只要一次更新成功，就认为成功
           $affect_status = false;
           $city = strtoupper($price_arr['city']);
           //找不到更新到哪个表，返回错误
           if(!isset($this->config->config[$city]) || !isset($price_arr['status']))
              return false;
           $table_name = $this->config->config[$city];
           $status = $price_arr['status'];
           $startDateunixTime =  strtotime($price_arr['startDate']);
           $endDateunixTime = strtotime($price_arr['endDate']);
           $week_start = $price_arr['week_start'];
           $week_end = $price_arr['week_end'];
           //周末范围
           $week_arr = array($week_start);
           //有周末价
           if(0 != $week_start && 0 != $week_end){
               if(!in_array($week_end,$this->week_set) || !in_array($week_start,$this->week_set)){
                   return false;
               }
               while($week_start != $week_end){
                   $week_start = (($week_start + 1) % 8 != 0)?$week_start + 1:1;
                   array_push($week_arr,$week_start);
               }
           }

           if(true == $status){
               // 一天的滴答数 = 86400
               for($dateunixTime = $startDateunixTime;$dateunixTime <= $endDateunixTime;
               $dateunixTime = $dateunixTime + 86400 ){
                   //取平时价
                   $price = ceil($price_arr['member']);
                   //转发为数据库要求的日期格式
                   $able_date = date("Y/m/d",$dateunixTime);
                   //判断是否为周末
                   $week_index = date("w",$dateunixTime);
                   if(0 == $week_index){
                       $week_index = 7;
                   }
                   //周末价
                   if(in_array($week_index,$week_arr)){
                       $price = ceil($price_arr['weekend']);
                      // echo 'The Date is in weekend';
                   }
                   //价格大于0，才为可售数据
                   //预订数据
                   $continue_days = '';
                   $first_bookable_date = '';
                   $first_bookable_time = '';
                   $latest_bookable_date = '';
                   $latest_bookable_time = '';
                   $special_type = false;
                   //早餐数据
                   $breakfast_mount = 0;
                   $breakfast_price = 0;
                   $breakfast_type = 0;
                   $price_arr['ratePlanName']  = urldecode($price_arr['ratePlanName']);
                   if($price > 0){
                       //置关房标志，关房原因清售价
                       $close_flag = "";
                       $close_reason = "";
                       $active = 1;

                   //是否可预订
                    $has_reserv = $price_arr['hasReserv'];
                      if( 1 ==  $has_reserv){
                          $maxAdvHours = $price_arr['maxAdvHours'];
                          $minAdvHours = $price_arr['minAdvHours'];
                          $continue_days = $price_arr['minRestrictNights'];
                          $first_bookable_date = date("Y/m/d",$dateunixTime- floor($maxAdvHours/24)*86400);
                          $first_bookable_time = ($maxAdvHours%24 > 0)?sprintf("%02d",24-$maxAdvHours%24).":00:00":"23:59:00";
                          $latest_bookable_date = date("Y/m/d",$dateunixTime- floor($minAdvHours/24)*86400);
                          $latest_bookable_time = ($minAdvHours%24>0)?sprintf("%02d",24 - $minAdvHours%24).":00:00":"23:59:00";
                      }
                   //计算早餐价格
                     foreach($price_arr['moings'] as $morning){
                         //早餐价格是否有特殊限定
                         if(isset($morning['weekset'])){
                             $breakfast_weekset = explode(',',$morning['weekset']);
                         }
                         //typecode 99 代表特殊早餐，如有特殊早餐，以特殊早餐为准
                         if('99' == $morning['typecode']){
                             if($dateunixTime >= $morning['startdate']/1000 && $dateunixTime <= $morning['enddate']/1000){
                                 //有设置星期几有效，需再判断一次
                                 if((isset($morning['weekset']) && in_array($week_index,$breakfast_weekset)) || (!isset($morning['weekset']))){
                                     //早餐是否免费
                                      if(0 == $morning['isinclude']){
                                         $breakfast_mount = 0;
                                         if('Percent' == $morning['priceoption'])
                                           $breakfast_price = $morning['price'] * $price /100 ;
                                         elseif('None' == $morning['priceoption'])
                                           $breakfast_price = 'null';
                                         else
                                           $breakfast_price = $morning['price'];
                                           $breakfast_type = 1;
                                 }
                                 else{
                                     $breakfast_mount = $morning['amount'];
                                 }
                                 break;
                                 }//
                             }
                         }
                         //typecode 01 代表早餐
                        elseif('01' == $morning['typecode'] ){
                            //早餐免费，显示数量，早餐收费，不显示数量
                              if(0 == $morning['isinclude'])
                                  $breakfast_mount = 0;
                               else{
                                   $breakfast_mount =$morning['amount'];
                                    break;
                               }
                            if('Percent' == $morning['priceoption'])
                                $breakfast_price = $morning['price'] * $price /100;
                            elseif('None' == $morning['priceoption'])
                                $breakfast_price = 'null';
                            else
                                $breakfast_price = $morning['price'];
                                $breakfast_type = 1;
                                break;
                        }
                     }//endforeach
                    //是否需要担保
                       $need_asssure = 0;
                    foreach($price_arr['needAssure'] as $assure){
                       if(isset($assure['weekset'])){
                            $assure_weekset = explode(',',$assure['weekset']);
                        }
                       if( $dateunixTime >= ($assure['startdate'] /1000) && $dateunixTime <= ($assure['enddate'] /1000)){
                          if((isset($assure['weekset']) && in_array($week_index,$assure_weekset)) || (!isset($assure['weekset'])))
                                 $need_asssure = 1;
                        }
                    }
                   }//endif(price == 0)
                   else{
                       $close_flag = "G";
                       $close_reason = "8";
                       //$price = 0;
                       $active = 0;
					   $need_asssure = '';
                   }
                    $query_str = sprintf("update %s SET CLOSEFLAG =  '%s',SALEPRICE =  %s ,ACTIVE =  %s ,".
                        " BREAKFASTTYPE = %d ,BREAKFASTNUMBER = %d,BREAKFASTPRICE = %s,NEED_ASSURE = '%s', ".
                        " BOOKSTARTDATE = to_date('%s','yyyy/mm/dd'), BOOKENDDATE = to_date('%s','yyyy/mm/dd'),MORNINGTIME = '%s',EVENINGTIME = '%s',".
                        "CONTINUEDAY = %d ,CURRENCY = '%s', CLOSEREASON = '%s',FREENET = %d,COMMODITYNAME  = '%s',LASTMODIFYTIME = sysdate ".
                        "WHERE COMMODITYID =  %s".
                        " AND ABLEDATE  =  to_date('%s','yyyy/mm/dd')  AND HOTELID =  %s  AND ROOMTYPEID =  %s",
                               $table_name,
                               $close_flag,
                               $price,
                               $active,
                               $breakfast_type,
                               $breakfast_mount,
                               $breakfast_price,
                               $need_asssure,
                               $first_bookable_date ,
                               $latest_bookable_date ,
                               $first_bookable_time ,
                               $latest_bookable_time,
                               $continue_days,
                               $price_arr['currencyCode'],
                               $close_reason,
                               $price_arr['wifi'],
                               $price_arr['ratePlanName'],
                               $price_arr['ratePlanIdMG'],
                               $able_date,
                               $price_arr['hotelIdMG'],
                               $price_arr['roomTypeIdMG']
                   );
                //   log_message('info',"****此时执行的SQL: {$query_str} *****");
                   if(false == $this->db->query($query_str))
                        return false;
                    if(0 !=  $this->db->affected_rows()){
                       $affect_status = true;
                  //    log_message('info',"****影响行数: {$this->db->affected_rows()} *****");
                   }
                    //需要写入日志表
                   elseif($NeedlogTable == True){
                    //  log_message('info',"****logStatus: {$NeedlogTable} *****");
                         $logTable = 'Htlquery_log';
                         $actionType = '修改操作';
                         $actionbusinessName ='价格';
                         $actionTable = $table_name;
                         $actionDateTime = 'sysdate';
                         $logStr = sprintf("insert into %s(QUERYID,ACTIONTYPE,ACTIONBUSINESSNAME,ACTIONTABLE,ACTIONDATETIME,"
             ."CLOSEFLAG,SALEPRICE,ACTIVE,BREAKFASTTYPE,BREAKFASTNUMBER,BREAKFASTPRICE,NEED_ASSURE,"
             ."BOOKSTARTDATE,BOOKENDDATE,MORNINGTIME,EVENINGTIME,CONTINUEDAY,CURRENCY,CLOSEREASON,FREENET,COMMODITYNAME,COMMODITYID,"
             ."ABLEDATE,HOTELID,ROOMTYPEID) values(seq_%s.nextval,'%s','%s','%s',%s,'%s',%s ,%s,%d,%d,%s,'%s',to_date('%s','yyyy/mm/dd'),".
             "to_date('%s','yyyy/mm/dd'),'%s','%s',%d,'%s','%s',%d,'%s',%s,to_date('%s','yyyy/mm/dd') ,%s ,%s)",
             $logTable,$logTable,$actionType,$actionbusinessName,$actionTable,$actionDateTime,
             $close_flag, $price, $active,$breakfast_type,$breakfast_mount,$breakfast_price,$need_asssure,$first_bookable_date,
             $latest_bookable_date ,$first_bookable_time ,$latest_bookable_time,$continue_days,$price_arr['currencyCode'],$close_reason,
             $price_arr['wifi'],$price_arr['ratePlanName'],$price_arr['ratePlanIdMG'],$able_date,$price_arr['hotelIdMG'],$price_arr['roomTypeIdMG']);

                   if(false == $this->db->query($logStr) ){
                       log_message('info',"****此时执行的SQL: {$logStr} *****");
                   }
                   }
               }//endfor
           }
           else {
               $price = 0;
               $close_flag = "G";
               $startDate=  date("Y/m/d",$startDateunixTime);
               $endDate = date("Y/m/d",$endDateunixTime);
               $query_str = sprintf("update %s SET CLOSEFLAG =  'G',SALEPRICE =  %s , LASTMODIFYTIME = sysdate, "
                   ."CLOSEREASON = '8' WHERE COMMODITYID =   %s".
  " AND ABLEDATE  BETWEEN to_date('%s','yyyy/mm/dd') AND to_date('%s','yyyy/mm/dd') AND HOTELID =  %s  AND ROOMTYPEID =  %s",
                   $table_name,
                   $price,
                   $price_arr['ratePlanIdMG'],
                   $startDate,
                   $endDate,
                   $price_arr['hotelIdMG'],
                   $price_arr['roomTypeIdMG']
               );
           //    log_message('info',"****此时执行的SQL: {$query_str} *****");
               if(false == $this->db->query($query_str))
                    return false;
               if( 0  != $this->db->affected_rows()){
               //    log_message('info',"****影响行数: {$this->db->affected_rows()} *****");
                   $affect_status = true;
               }
               //需要写入日志表
               elseif($NeedlogTable){
                   log_message('info',"****logStatus: {$NeedlogTable} *****");
                   $logTable = 'Htlquery_log';
                   $actionType = '修改操作';
                   $actionbusinessName ='价格';
                   $actionTable = $table_name;
                   $actionDateTime = 'sysdate';
                   $close_reason = '8';
                   for($dateunixTime = $startDateunixTime;$dateunixTime <= $endDateunixTime;
                       $dateunixTime = $dateunixTime + 86400 ){
                       //转发为数据库要求的日期格式
                       $able_date = date("Y/m/d",$dateunixTime);
                 $logStr = sprintf("insert into %s(QUERYID,ACTIONTYPE,ACTIONBUSINESSNAME,ACTIONTABLE,ACTIONDATETIME,"
                 ."CLOSEFLAG,SALEPRICE,CLOSEREASON,COMMODITYID,ABLEDATE,HOTELID,ROOMTYPEID) values(seq_%s.nextval,'%s','%s','%s',%s"
                 .",'%s',%s,'%s',%s,to_date('%s','yyyy/mm/dd') ,%s ,%s)"
                     ,$logTable,$logTable,$actionType,$actionbusinessName,$actionTable,$actionDateTime,$close_flag,
                 $price,$close_reason,$price_arr['ratePlanIdMG'],$able_date,$price_arr['hotelIdMG'],$price_arr['roomTypeIdMG']);
                       if(false == $this->db->query($logStr) ){
                           log_message('info',"****此时执行的SQL: {$logStr} *****");
                       }

                   }
               }
               //$tmpVar = $this->db->affected_rows();
           }
         //  $end = microtime(true);
         //  $exec = $end - $start;
          // log_message('info',"执行时间为:$exec");
           return $affect_status;
       }catch (Exception $e){
           return false;
       }
   }

    /** 已经过时
     * 更新库存
     *
     * {"amount":5,"city":"HKG","date":"2014-05-29 00:00:00","endDate":"2014-05-30 23:59:59",
     * "endTime":"23:59:59","hotelCode":"00801055","hotelID":"00801055","hotelIDMG":"30001467",
     * "lastId":4257819082,"overBooking":0,"roomTypeId":"0001","roomTypeIdMG":"261530",
     * "startDate":"2013-08-02 02:29:05","startTime":"00:00:00","status":true,"time":"2014-05-26 08:54:08"}
     *
     * 判断逻辑
     * status为false时，数据库配额数字段QUOTANUMBER置0，置关房标志"G",HASBOOK可预订字段为0，HASOVERDRAFT可透支字段为1,abledate 取 date
     * status为true时, 若amount = 0,且overbooking字段 = 1(不可超售)，处理同status = FALSE时的情况
     * status为true时，数据库配额数字段QUOTANUMBER置$amount,置关房标志为"",HASBOOK可预订字段为1, abledate 取 date 到 enddate
     * HASOVERDRAFT可透支字段为$overbooking
     *
     *
     * set value
     * QUOTANUMBER  配额数  $amount
     * HASOVERDRAFT 能否透支 $OverBooking
     * CLOSEFLAG 开关状态 (在不可卖时，变为"G"，可卖时，变为"")
     * HASBOOK  可预订 0/1
     *
     * where condition
     * ABLEDATE 日期 (用between  $startDate and endDate $endDate)
     * ROOMTYPEID 房型ID $roomTypeIdMG
     * HOTELID 酒店Id，$hotelIdMG
     *

     */
    public function hotel_inventory_update($inventory_string,$NeedlogTable){
      //  $inventory_string =  utf8_encode($inventory_string);
       $inventory_arr = json_decode($inventory_string,true);
        if(!is_array($inventory_arr)){
            return false;
        }
        try{
          //  $this->db->reconnect();
            $affect_status = false;
            $city = strtoupper($inventory_arr['city']);
            //找不到更新到哪个表，返回错误
            if(!isset($this->config->config[$city]) || !isset($inventory_arr['status']))
                return false;
            $table_name = $this->config->config[$city];
            $status = $inventory_arr['status'];
            $startDate =  date("Y/m/d",strtotime($inventory_arr['date']));
            $endDate = date("Y/m/d",strtotime($inventory_arr['endDate']));
            $amount = $inventory_arr['amount'];
            $overBooking = $inventory_arr['overBooking'];
            if(true == $inventory_arr['status'] && ($amount > 0 || (0 == $amount &&  0 != $overBooking)) ){
                $close_flag = '';
                $has_book = 1;
                if('1970/01/01' == $startDate ||'1970/01/01' == $endDate ){
                    log_message('info',"*** json_string: {$inventory_string} *****");
                    return false;
                }
            }
            else{
                $close_flag = 'G';
                $has_book = 0;
                $amount = 0;
                $endDate = $startDate;
            }
            $query_str = sprintf("update %s SET CLOSEFLAG =  '%s',QUOTANUMBER =  %s ,HASOVERDRAFT = %s,HASBOOK =  %s , LASTMODIFYTIME = sysdate WHERE ".
                 "ABLEDATE  = to_date('%s','yyyy/mm/dd')  AND HOTELID =  %s  AND ROOMTYPEID =  %s and SALEPRICE > 0",
                $table_name,
                $close_flag,
                $amount,
                $overBooking,
                $has_book,
                $startDate,
                $inventory_arr['hotelIDMG'],
                $inventory_arr['roomTypeIdMG']
            );
          //  log_message('info',"****此时执行的SQL: {$query_str} *****");
            if(false == $this->db->query($query_str))
                return false;
            if ( 0 != $this->db->affected_rows()){
          //      log_message('info',"****影响行数: {$this->db->affected_rows()} *****");
                $affect_status = true;
            }
            //需要写入日志表
            elseif($NeedlogTable){
                $logTable = 'Htlquery_log';
                $actionType = '修改操作';
                $actionbusinessName ='库存';
                $actionTable = $table_name;
                $actionDateTime = 'sysdate';
                //$close_reason = '8';

           $logStr = sprintf("insert into %s (QUERYID,ACTIONTYPE,ACTIONBUSINESSNAME,ACTIONTABLE,ACTIONDATETIME,CLOSEFLAG,QUOTANUMBER,HASOVERDRAFT,HASBOOK,ABLEDATE,HOTELID,ROOMTYPEID)"
             ."values(seq_%s.nextval,'%s','%s','%s',%s,'%s',%s,%s,%s,to_date('%s','yyyy/mm/dd'),%s,%s) ",
               $logTable,$logTable,$actionType,$actionbusinessName,$actionTable,$actionDateTime,
               $close_flag,$amount,$overBooking,$has_book, $startDate, $inventory_arr['hotelIDMG'],$inventory_arr['roomTypeIdMG']);
                if(false == $this->db->query($logStr) ){
                    log_message('info',"****此时执行的SQL: {$logStr} *****");
                }

            }
          //  $tmpVar = $this->db->affected_rows();
            return $affect_status;

        }catch (Exception $e){
            return false;
        }
    }

    /**
     *  {"hotelID": "30179125","priceTypeId": "467376,467373", "city":"SZX"} (可能存在多个,以英文字符隔开)
     *
     *
     *
     */
    public  function  close_hotel_sales($deldata_string,$NeedlogTable){
      // $deldata_string =  utf8_encode($deldata_string);
        $deldata_arr = json_decode($deldata_string,true);
        if(!is_array($deldata_arr)){
            return false;
        }
        try{
            //$this->db->reconnect();
            $affect_status = false;
            $city = strtoupper($deldata_arr['city']);

            //找不到更新到哪个表，返回错误
            if(!isset($this->config->config[$city]) || !isset($deldata_arr['hotelID'])  || !isset($deldata_arr['priceTypeId']) )
                return false;
            $table_name = $this->config->config[$city];
            //价格计划分解
            $priceTypeId_arr =  explode(',',$deldata_arr['priceTypeId']);
            //验证每个价格是否正确

            foreach($priceTypeId_arr as $priceTypeId){
                if(empty($priceTypeId)){
                    return false;
                }
            }

            $query_str = sprintf("delete from %s WHERE "." HOTELID = %s AND COMMODITYID IN (%s)",
                $table_name,
                $deldata_arr['hotelID'],
                $deldata_arr['priceTypeId']
            );
          //  log_message('info',"****此时执行的SQL: {$query_str} *****");
            if(false == $this->db->query($query_str))
                 return false;
            if( 0 != $this->db->affected_rows()){
                $affect_status = true;
           //    log_message('info',"****影响行数: {$this->db->affected_rows()} *****");
            }
            //需要写入日志表
            elseif($NeedlogTable){
                 //  log_message('info',"****logStatus: {$NeedlogTable} *****");
                $logTable = 'Htlquery_log';
                $actionType = '删除操作';
                $actionbusinessName ='价格计划';
                $actionTable = $table_name;
                $actionDateTime = 'sysdate';
                foreach($priceTypeId_arr as $price ){
               $logStr = sprintf("insert into %s (QUERYID,ACTIONTYPE,ACTIONBUSINESSNAME,ACTIONTABLE,ACTIONDATETIME,HOTELID,COMMODITYID) values("
               ."seq_%s.nextval,'%s','%s','%s',%s,%s,%s)",$logTable,$logTable,$actionType,$actionbusinessName,
                $actionTable,$actionDateTime ,$deldata_arr['hotelID'],$price);
                    if(false == $this->db->query($logStr) ){
                        log_message('info',"****此时执行的SQL: {$logStr} *****");
                    }

                }

            }
            return $affect_status;

        }catch (Exception $e){
            return false;
        }
    }
    //{"addBed":"2","city":"OTHER","delBed":"","hotelID":30180771,"oldBed":"2","roomId":449200,"updateBed":""}
    public function update_hotel_roomType($roomType_string,$NeedlogTable){
      // $roomType_string =  utf8_encode($roomType_string);
      //  $roomType_string = '{"addBed":"1,2","city":"HBQ","delBed":"","hotelID":30179458,"oldBed":"3","roomId":437021,"updateBed":""}';
        $roomType_arr = json_decode($roomType_string,true);
        if(!is_array($roomType_arr)){
            return false;
        }
        try{
            //$this->db->reconnect();
            $affect_status = false;
            $city = strtoupper($roomType_arr['city']);
            //找不到更新到哪个表，返回错误
            if(!isset($this->config->config[$city]) || !isset($roomType_arr['hotelID'])  || !isset($roomType_arr['roomId']) )
                return false;
            $table_name = $this->config->config[$city];
            //如果update字段非空
            if(!empty($roomType_arr['updateBed'])){
            $updateBed = array();
            list($updateBed['old'],$updateBed['new']) = explode(':',$roomType_arr['updateBed']);
             $queryUpdateStr = sprintf("update %s set bedtype = '%s', LASTMODIFYTIME = sysdate where roomtypeid = %d and hotelid = %d and bedtype = '%s' ",
                 $table_name,
                 $updateBed['new'],
                 $roomType_arr['roomId'],
                 $roomType_arr['hotelID'],
                 $updateBed['old']);
              //   log_message('info',"****此时执行的SQL: {$queryUpdateStr} *****");
                 if( false == $this->db->query($queryUpdateStr) )
                    return false;
                 if( 0 != $this->db->affected_rows()){
                     $affect_status = true;
                //     log_message('info',"****影响行数: {$this->db->affected_rows()} *****");
                 }
                 //需要写入日志表
                 elseif($NeedlogTable){
                     $logTable = 'Htlquery_log';
                     $actionType = '修改操作';
                     $actionbusinessName ='床型';
                     $actionTable = $table_name;
                     $actionDateTime = 'sysdate';
                     $logStr = sprintf("insert into %s (QUERYID,ACTIONTYPE,ACTIONBUSINESSNAME,ACTIONTABLE,ACTIONDATETIME,BEDTYPE,HOTELID,ROOMTYPEID) values("
                         ."seq_%s.nextval,'%s','%s','%s',%s,'%s:%s',%s,%s)",$logTable,$logTable,$actionType,$actionbusinessName,
                         $actionTable,$actionDateTime ,$updateBed['old'],$updateBed['new'],$roomType_arr['hotelID'],$roomType_arr['roomId']);
                     if(false == $this->db->query($logStr) ){
                         log_message('info',"****此时执行的SQL: {$logStr} *****");
                     }

                 }
            }
            //如果addBed字段非空
            if(!empty($roomType_arr['addBed']) && !empty($roomType_arr['oldBed']) ){
                   $addBedArr = explode(',',$roomType_arr['addBed']);
                   foreach($addBedArr as $addBed){
                       $qStr = sprintf("insert into %s (QUERYID,DISTID,ABLEDATE,DISTCHANNEL,MEMBERTYPE,USERTYPE,CLOSEFLAG,PAYMETHOD,"
                           ."COMMODITYID,COMMODITYNAME,COMMODITYNO,COMMODITYCOUNT,BEDTYPE,ROOMTYPEID,ROOMTYPENAME,HOTELID,HDLTYPE,PRICEID,SALEPRICE,".
                           "SALESROOMPRICE,BREAKFASTTYPE,BREAKFASTNUMBER,BREAKFASTPRICE,CURRENCY,DEALER_FAVOURABLEID,DEALER_PROMOTIONSALEID,PROVIDER_FAVOURABLEID,".
                           "PROVIDER_PROMOTIONSALEID,BOOKCLAUSEID,PAYTOPREPAY,BOOKSTARTDATE,BOOKENDDATE,MORNINGTIME,EVENINGTIME,CONTINUUM_IN_END,CONTINUUM_IN_START,".
                           "MUST_IN,RESTRICT_IN,CONTINUE_DATES_RELATION,NEED_ASSURE,QUOTANUMBER,HASBOOK,HASOVERDRAFT,CLOSEREASON,CONTINUEDAY,COMMISSIONRATE,COMMISSION,".
                           "FORMULA,FREENET,ACTIVE,DISTRIBCHANNEL,SUPPLIERID,LASTMODIFYTIME,ADVICE_PRICE) ".
                           "select seq_%s.nextval,DISTID,ABLEDATE,DISTCHANNEL,MEMBERTYPE,USERTYPE,CLOSEFLAG,PAYMETHOD,"
                           ."COMMODITYID,COMMODITYNAME,COMMODITYNO,COMMODITYCOUNT,'%s',ROOMTYPEID,ROOMTYPENAME,HOTELID,HDLTYPE,PRICEID,SALEPRICE,".
                           "SALESROOMPRICE,BREAKFASTTYPE,BREAKFASTNUMBER,BREAKFASTPRICE,CURRENCY,DEALER_FAVOURABLEID,DEALER_PROMOTIONSALEID,PROVIDER_FAVOURABLEID,".
                           "PROVIDER_PROMOTIONSALEID,BOOKCLAUSEID,PAYTOPREPAY,BOOKSTARTDATE,BOOKENDDATE,MORNINGTIME,EVENINGTIME,CONTINUUM_IN_END,CONTINUUM_IN_START,".
                           "MUST_IN,RESTRICT_IN,CONTINUE_DATES_RELATION,NEED_ASSURE,QUOTANUMBER,HASBOOK,HASOVERDRAFT,CLOSEREASON,CONTINUEDAY,COMMISSIONRATE,COMMISSION,".
                           "FORMULA,FREENET,ACTIVE,DISTRIBCHANNEL,SUPPLIERID,sysdate,ADVICE_PRICE from %s  where roomtypeid = %d and hotelid = %d and bedtype = '%s' and abledate >=  to_date('%s','yyyy/mm/dd')",
                           $table_name,
                           $table_name,
                           $addBed,
                           $table_name,
                           $roomType_arr['roomId'],
                           $roomType_arr['hotelID'],
                           $roomType_arr['oldBed'],
                           date("Y/m/d",time()-3600*24));
                  //    log_message('info',"****此时执行的SQL: {$qStr} *****");
                     if(false == $this->db->query($qStr) )
                           return false;
                       if( 0 != $this->db->affected_rows()){
                           $affect_status = true;
                      //    log_message('info',"****影响行数: {$this->db->affected_rows()} *****");
                   }
                       //需要写入日志表
                       elseif($NeedlogTable){
                           $logTable = 'Htlquery_log';
                           $actionType = '插入操作';
                           $actionbusinessName ='床型';
                           $actionTable = $table_name;
                           $actionDateTime = 'sysdate';
                           $logStr = sprintf("insert into %s (QUERYID,ACTIONTYPE,ACTIONBUSINESSNAME,ACTIONTABLE,ACTIONDATETIME,BEDTYPE,HOTELID,ROOMTYPEID) values("
                               ."seq_%s.nextval,'%s','%s','%s',%s,'%s',%s,%s)",$logTable,$logTable,$actionType,$actionbusinessName,
                               $actionTable,$actionDateTime ,$roomType_arr['oldBed'],$roomType_arr['hotelID'],$roomType_arr['roomId']);
                           if(false == $this->db->query($logStr) ){
                               log_message('info',"****此时执行的SQL: {$logStr} *****");
                           }

                       }
                  }//endforeach
            }//addBed
            /////
            if(!empty($roomType_arr['delBed'])){
                $delBedArr = explode(',',$roomType_arr['delBed']);
                foreach($delBedArr as $delBed){
                    $querydelStr = sprintf("delete from  %s where bedtype = '%s' and roomtypeid = %d and hotelid = %d",
                        $table_name,
                        $delBed,
                        $roomType_arr['roomId'],
                        $roomType_arr['hotelID']);
                  //  log_message('info',"****此时执行的SQL: {$querydelStr} *****");
                    if(false == $this->db->query($querydelStr) )
                        return false;
                    if( 0 != $this->db->affected_rows()){
                        $affect_status = true;
                     //   log_message('info',"****影响行数: {$this->db->affected_rows()} *****");
                    }
                    //需要写入日志表
                    elseif($NeedlogTable){
                        $logTable = 'Htlquery_log';
                        $actionType = '删除操作';
                        $actionbusinessName ='床型';
                        $actionTable = $table_name;
                        $actionDateTime = 'sysdate';
                        $logStr = sprintf("insert into %s (QUERYID,ACTIONTYPE,ACTIONBUSINESSNAME,ACTIONTABLE,ACTIONDATETIME,BEDTYPE,HOTELID,ROOMTYPEID) values("
                            ."seq_%s.nextval,'%s','%s','%s',%s,%s,%s,%s)",$logTable,$logTable,$actionType,$actionbusinessName,
                            $actionTable,$actionDateTime , $delBed,$roomType_arr['hotelID'],$roomType_arr['roomId']);
                        if(false == $this->db->query($logStr) ){
                            log_message('info',"****此时执行的SQL: {$logStr} *****");
                        }

                    }
                }
            }//delBed
            return $affect_status;
         }catch (Exception $e){
           return false;
     }//catch
    }//function
    public function hotel_keep_connect(){
         $result =  $this->db->query("select * from dual");
               if($result == false || $result->num_rows() == 0){
                   return false;
               }
               else{
                   return true;
               }
    }
}
