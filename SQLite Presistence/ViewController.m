//
//  ViewController.m
//  SQLite Presistence
//
//  Created by 张光发 on 15/11/15.
//  Copyright © 2015年 张光发. All rights reserved.
//

#import "ViewController.h"
#import <sqlite3.h>

@interface ViewController ()
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *lineFields;

@end

@implementation ViewController

-(NSString *)dataFilePath
{
    /*
     获取程序document目录
     NSDocumentDirectory 是指程序中对应的Documents路径，而NSDocumentionDirectory对应于程序中的Library/Documentation路径，这个路径是没有读写权限的，所以看不到文件生成。
     NSUserDomainMask是把搜索范围限制在沙盒内
     */
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *documentsDirectory=[paths objectAtIndex:0];
    NSLog(@"获取到的目录是：%@",documentsDirectory);
    
    {
        //参考http://blog.csdn.net/xingxing513234072/article/details/24184917
        NSString *path2=NSHomeDirectory();
        NSLog(@"获取的主目录是：%@",path2);
    }
    
    return [documentsDirectory stringByAppendingPathComponent:@"data.sqlite"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*
     打开数据库连接
     [1]数据库的完整路径，不存在会自动创建，存在尝试打开，
     [2]sqlite数据库指针
     
     SQLITE_OK是sqlite操作成功的标识
     */
    sqlite3 *database;
    if (sqlite3_open([[self dataFilePath] UTF8String], &database)!=SQLITE_OK){
        //关闭数据库连接
        sqlite3_close(database);
        NSAssert(0, @"打开数据库失败1");
    }
    
    //建表语句
    NSString *createSQL=@"create table if not exists fields (raw integer primary key,field_data text);";
    //c类型的字符串
    char *errorMsg;
    /*
     执行SQL语句
     [1]sqlite数据库指针
     [2]SQL语句
     [3]回调函数
     [4]回调函数的参数
     [5]错误信息
     */
    if (sqlite3_exec(database, [createSQL UTF8String], NULL, NULL, &errorMsg)!=SQLITE_OK) {
        sqlite3_close(database);
        //断言，如果条件为假就抛出异常
        NSAssert(0, @"创建表失败，内容：%s",errorMsg);
    }
    
    //查询语句
    NSString *query=@"select raw,field_data from fields order by raw";
    //编译后的sql语句
    sqlite3_stmt *statement;
    /*
     sqlite3_prepare -编译SQL语句
     [1]数据库指针
     [2]sql语句
     [3]
     [4]编译后的对象
     */
    if (sqlite3_prepare(database, [query UTF8String], -1, &statement, nil)==SQLITE_OK) {
        /*
         sqlite3_step -执行SQL语句
         [1]编译后的SQL语句
         
         只查询一行结果，这个语句执行到结果的第一行可用的位置。
         如果要继续查询就再次调用
         */
        while (sqlite3_step(statement)==SQLITE_ROW) {
            int row = sqlite3_column_int(statement, 0);
            char *rowData=(char *)sqlite3_column_text(statement, 1);
            
            NSString *fieldValue=[[NSString alloc] initWithUTF8String:rowData];
            UITextField *field=self.lineFields[row];
            field.text=fieldValue;
        }
        //销毁编译后的SQL语句
        sqlite3_finalize(statement);
    }
    //关闭数据库连接
    sqlite3_close(database);
    
    UIApplication *app=[UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:app];
}

/*
 收到UIApplicationWillResignActiveNotification(程序不在活跃并且失去焦点)的通知时的调用函数
 
 打开数据库连接
 把文本框的内容存储到数据库
 关闭数据库连接
 */
-(void)applicationWillResignActive:(NSNotification *)notification
{
    sqlite3 *database;
    if (sqlite3_open([[self dataFilePath] UTF8String], &database)!=SQLITE_OK) {
        sqlite3_close(database);
        NSAssert(0, @"打开数据库失败");
    }
    for (int i=0; i<4; i++) {
        UITextField *file=self.lineFields[i];
        //NSLog(@"%d的text是%@",i,file.text);
        char *update="insert or replace into fields(raw,field_data) values (?,?);";
        char *errormsg=NULL;
        sqlite3_stmt *stmt;
        if (sqlite3_prepare(database, update, -1, &stmt, nil)==SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, i);
            sqlite3_bind_text(stmt, 2, [file.text UTF8String], -1, NULL);
        }
        if (sqlite3_step(stmt)!=SQLITE_DONE) {
            NSAssert(0,@"更新失败%s",errormsg);
        }
        sqlite3_finalize(stmt);
    }
    sqlite3_close(database);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
