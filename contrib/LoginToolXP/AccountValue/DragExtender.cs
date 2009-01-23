using System;
using System.Windows.Forms;
using System.ComponentModel;
using System.ComponentModel.Design;
using System.Drawing;
using System.Collections;
using System.Runtime;
using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using System.Diagnostics;

namespace AccountValue
{

	[ProvideProperty("Draggable", typeof(Control))]
	public class DragExtender : System.ComponentModel.Component, IExtenderProvider
	{

		private const int WM_SYSCOMMAND = 0x112;
		private const int MOUSE_MOVE = 0xF012;
		[DllImport("User32.dll")]
		private static extern int SendMessage(IntPtr hWnd, 
			int msg , int wParam , ref int lParam);

		[DllImport("User32.dll")]
		private static extern int SendMessage(IntPtr hWnd, 
			int msg , int wParam , int[] lParam);
		[DllImport("user32")] 
		public static extern int ReleaseCapture(IntPtr hwnd);




		private System.ComponentModel.Container _container;
		public DragExtender()
		{
			_container = new System.ComponentModel.Container();
		}
		#region IExtenderProvider Members

		public bool CanExtend(object extendee)
		{
			// TODO:  Add DragExtender.CanExtend implementation
			return (extendee is Control);
			//return false;
		}
		
		#endregion

		public bool GetDraggable(Control control)
		{
			foreach(Control ctrl in _container.Components)
			{
				if (control==ctrl) return true;
			}
			return false;
		}

		public void SetDraggable(Control control, bool value)
		{
			if (value)
			{
				if (!GetDraggable(control))
				{
					this._container.Add(control);
					control.MouseDown+=new MouseEventHandler(control_MouseDown);
				}
			} 
			else
				if (GetDraggable(control))
			{
				_container.Remove(control);
			}
		
		}

		private Form m_form = null;
		public Form Form
		{
			get { return m_form; } 
			set { m_form = value; } 
		}
		

		private void control_MouseDown(object sender, MouseEventArgs e)
		{
			if (!DesignMode && m_form!=null)
			{
				Control control = sender as Control;
				ReleaseCapture(control.Handle);
				int nul =0;
				SendMessage(m_form.Handle, WM_SYSCOMMAND, MOUSE_MOVE, ref nul);
			}
		}
	}
}